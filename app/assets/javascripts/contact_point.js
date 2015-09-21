var ContactPointsController = Paloma.controller('ContactPoints');

ContactPointsController.prototype.index = function() {
  disable_enter_on_phone();

  $('#contact_points').on('click', '.clone-link', clone_phone);
  $('#add_both_phones').on('click', add_both_phones);
  $('.add-as-link').on('click', function() {
      $(this).closest('form').find('#contact_point_contact_type').val($(this).data('type'));
  });
};

ContactPointsController.add_email = function(email_html) {
  add_contact_point('email', email_html);
};

ContactPointsController.add_phone = function(phone_html, phone_type) {
  add_contact_point(phone_type, phone_html, 'phone');
};

ContactPointsController.update_contact_point = function(dom_id, html) {
  $('#' + dom_id).replaceWith(html);
};

ContactPointsController.remove_contact_point = function(dom_id) {
  $('#' + dom_id).remove();
};

ContactPointsController.show_voice_code = function(code, seconds_for_countdown, cancel_url, refresh_url) {
  var container = $('#phone_verification_container');
  container.find('#voice_verification_code').text(code).removeClass('invisible');

  start_calling_timer(container, seconds_for_countdown);

  container.find('#verify_action').addClass('hidden');
  container.find('#cancel_call').removeClass('hidden');

  if (cancel_url) container.find('#cancel_call').attr('href', cancel_url);
  container.closest('.modal').on('hidden.bs.modal', RequestOptionsPageManager.setup);
  if (refresh_url) container.closest('.modal').on('hidden.bs.modal', function() { $.get(refresh_url); });
};

ContactPointsController.setup_verification_form = function(verify_url) {
  var container = $('#phone_verification_container');

  $('#verify_by_call', container).off('click').on('click', show_voice_verification);
  $('#verify_by_sms', container).off('click').on('click', show_sms_verification);
  if ($('.sms_verification', container).length)
    show_sms_verification();
  else
    show_voice_verification();

  $('#verify_action', container).removeClass('hidden').attr('href', verify_url);
  $('#verify_cancel_button', container).removeClass('hidden');
  $('#cancel_call', container).addClass('hidden');
  $('#voice_verification_code', container).addClass('invisible');
  $('#voice_verification_countdown', container).addClass('invisible').html('Calling in <span></span>');
};

ContactPointsController.show_voice_verification_modal = function(verify_url) {
  var modal = $('#aux_modal');
  $('verify_cancel_button', modal).text('Cancel');
  $('verify_cancel_button', modal).text('Close');
  ContactPointsController.setup_verification_form(verify_url);
  modal.off('hidden.bs.modal').modal('show');
};

ContactPointsController.append_code_error = function(error) {
  $('#phone_verification_container').find('.code_error').html(error);
};

ContactPointsController.close_verification_modal = function() {
  $('#phone_verification_container').closest('.modal').modal('hide');
};

var clone_phone = function(e) {
  e.preventDefault();
  var clicked_link = $(this);
  $.post($(this).attr('href'), { contact_point: { contact_type: $(this).data('as'), description: $(this).data('number')} }, function() {
    clicked_link.prev().remove();
    clicked_link.remove();
  });
};

var disable_enter_on_phone = function() {
  $('#new_phone_container').find('#new_contact_point').on('keyup keypress', function(e) {
    var code = e.keyCode || e.which;
    if (code  == 13) {
      e.preventDefault();
      return false;
    }
  });
};

var add_contact_point = function(type, html, new_cp_type) {
  if (!new_cp_type) new_cp_type = type;
  $('#' + type + 's').append(html);
  $('#new_' + new_cp_type + '_container').find('.contact-point-description').val('');
};

var add_both_phones = function(e) {
  e.preventDefault();
  var number = $('#new_phone_container').find('#contact_point_description').val();
  $.post($(this).data('url'), { contact_point: { description: number } });
};

var start_calling_timer = function(modal, seconds_left) {
  var countdown_container = modal.find('#voice_verification_countdown').removeClass('invisible');
  var countdown = countdown_container.find('span').text('00:' + ('00' + seconds_left).substr(-2, 2));
  var timer_id = setInterval(function() {
    seconds_left--;
    if (seconds_left) countdown.text('00:' + ('00' + seconds_left).substr(-2, 2));
    else {
      clearInterval(timer_id);
      countdown_container.text('Calling...');
    }
  }, 1000);
};

var show_sms_verification = function() {
  var container = $('#phone_verification_container');
  container.find('.voice_verification, .voice_actions').hide();
  container.find('.sms_verification, .sms_actions').show();
}

var show_voice_verification = function() {
  var container = $('#phone_verification_container');
  container.find('.sms_verification, .sms_actions').hide();
  container.find('.voice_verification, .voice_actions').show();
}

var submit_sms_verification = function(e) {
  e.preventDefault();
  $('.sms-verif-form').submit();
}