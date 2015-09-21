var LineItemsController = Paloma.controller('LineItems');

LineItemsController.prototype.show = function(){
  var resource_select = new ResourceSelect(this.params['resources']);

  var length_picker = new LengthTimePicker(
    $(".length_picker", "#line_item_length_picker_container"),
    $(".length_control", "#line_item_length_picker_container"),
    $('#line_item_length')
  );

  var compoundDatePicker = new CompoundDatePicker({
    start: $(".earliest_start_picker",'#line_item_earliest_start_container'), 
    ideal:  $(".ideal_start_picker","#line_item_ideal_start_container"),
    finish: $(".finish_by_picker",'#line_item_finish_by_container'),
    start_control: $(".earliest_start_control",'#line_item_earliest_start_container'),
    ideal_control: $(".ideal_start_control",'#line_item_ideal_start_container'),
    finish_control: $(".finish_by_control",'#line_item_finish_by_container'),
    start_input: $("#line_item_earliest_start"),
    ideal_input: $("#line_item_ideal_start"),
    finish_input: $("#line_item_finish_by"),
    length: length_picker,
    start_view: 1,
    ideal_view: 1,
    finish_view: 1,
    start_max_view: 2,
    ideal_max_view: 2,
    finish_max_view: 2,
    edit_mode: true, 
    tmz: this.params["request_tmz"]
  });

  setup_disable_with();
  setup_original_values();
  setup_changes_detector();

  var request = new LineItemCustomize();
  var line = $("#edit_line_item_1");
  request.set_request(this.params["request"]);
  request.track_modifications(line);

  line.on("blur", ".form-control", function(){
    var field = $(this).attr("class").split(" ").pop();

    if(field.indexOf("control") == -1){
      request.track_field(line,field, request.get_values());
    }
  });

  line.on("hidden.bs.modal", ".modal", function(){
    var field = $(this).attr("class").split(" ")[1];
    request.track_field(line, field, request.get_values());
  });
};

var setup_disable_with = function() {
  $('.edit_line_item :submit').click( function () {
    var buttons = $('.edit_line_item :submit').not($(this));
    buttons.removeAttr('data-disable-with');
    buttons.attr('disabled', true);
  });
};

var setup_original_values = function(){
  $('.edit_line_item').find('input').each(function() {
    if (!$(this).data('originalValue')) $(this).data('originalValue', $(this).val());
  });
};

var setup_changes_detector = function() {
  var form = $('.edit_line_item');
  var submit_button = form.find('#submit_changes_button');
  if (!submit_button.data('acceptable')) return;

  var non_acceptable_caption = submit_button.val();
  var ideal_label = form.find('label[for="ideal_start"]');
  var non_acceptable_ideal_label = ideal_label.text();
  form.on('change', function() {
    if (changes_require_confirmation()) {
      submit_button.val(non_acceptable_caption);
      ideal_label.text(non_acceptable_ideal_label);
    }
    else {
      submit_button.val('Accept');
      ideal_label.text('Agreed start');
    }
  }).trigger('change');
};

var changes_require_confirmation = function() {
  return time_window_broaded() || confirmable_fields_changed();
};

var time_window_broaded = function() {
  var input, previous, actual;
  input = $('#line_item_earliest_start');
  previous = input.data('originalValue');
  actual = input.val();
  if (previous && (!actual || moment(actual).isBefore(previous))) return true;
  input = $('#line_item_finish_by');
  previous = input.data('originalValue');
  actual = input.val();
  if (previous && (!actual || moment(actual).isAfter(previous))) return true;
};

var confirmable_fields_changed = function() {
  var form = $('.edit_line_item');
  var changed_fields = form.find('input').filter(function() {
    return $(this).data('mustConfirm') && $(this).data('originalValue') && $(this).val().trim() != $(this).data('originalValue');
  });
  return !!changed_fields.length;
};
