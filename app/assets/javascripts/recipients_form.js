function RecipientsForm(container, parent){
  this.recipients = {};
  this.new_recipients = {};
  this.parent = parent;
  this.container = container;
  this.email_container = this.container.find('.email');
  this.phone_container = this.container.find('.phone');
  this.org_resource_picker = null;
  this.bind_events();
  this.add_flow = 0;
};

RecipientsForm.prototype.bind_events = function(){
  $(".add_recipient").click(function(){
    this.add_recipient();
  }.bind(this));

  $('.lookup_btn', this.email_container).click(this.add_as_email.bind(this));
  $('.lookup_btn', this.phone_container).click(this.add_as_phone.bind(this));

  $("#recipients_form_page_1 .add_by_phone", this.container).click(function(){
    this.goto_page(2);
    // trying to force the focus of first input on 'add by phone' page
    $('.recipients_page.phone input').first().focus();
  }.bind(this));

  $("#recipients_form_page_1 .add_by_email", this.container).click(function(){
    this.goto_page(3)
  }.bind(this));

  $("#recipients_form_page_1 .add_by_organization", this.container).click(this.goto_add_by_org.bind(this));

  $('.contact_point', this.container).keypress(function(e){
    if( e.which == 13) $(".lookup_btn", this.container).trigger('click');
  });

};

RecipientsForm.prototype.subscribe_to_back = function(callback){
  $(".recipients_page_1.back_page").click(function(){
    this.hide();
    callback();
  }.bind(this));
};

RecipientsForm.prototype.subscribe_to_back_global = function(callback){
  $(".recipients_page_2.back_page, .recipients_page_3.back_page, .recipients_page_4.back_page, .submenu_recipients.back_page").click(function(){
    this.back_to_list();
    callback();
  }.bind(this));
};

RecipientsForm.prototype.goto_page = function(page){
  $('.request_page_nav').hide();
  $(".recipients_page", this.container).hide();
  $(".recipients_page_nav").hide();
  $("#recipients_page_"+page+"_nav").show();
  $("#recipients_form_page_"+page).show();

  $('input', this.container).filter(':visible').focus();
};

RecipientsForm.prototype.add_as_email = function(){
  this.add_flow = 2;
  var email = this.get_cp(this.email_container);
  var validations = new Validations();

  if(!validations.valid_email(email) || email == ""){
    $(".error_label", this.email_container).show();
  }else{
    this.show_resource_picker({email: email}, '.email');
  }
};

RecipientsForm.prototype.add_as_phone = function(){
  this.add_flow = 1;
  var number = this.get_cp(this.phone_container);
  var validations = new Validations();

  if(!validations.valid_phone(number) || number == ""){
    $(".error_label", this.phone_container).show();
  }else{
    this.show_resource_picker({voice: number}, '.phone');
  }
};

RecipientsForm.prototype.show_resource_picker = function(cp, container_selector, use_organization_select){
  var cp_container = $(container_selector);
  $(".error_label").hide();

  var select1 = container_selector + " input.organizations_list";
  var select2 = container_selector + " input.resources_list";
  this.org_resource_picker = (use_organization_select)? new ByOrganizationSelect(this.org_lookup_by_id_url(), select1 , select2) : new ByContactPointSelect(this.org_lookup_by_cp_url(), select1 , select2, cp);

  $(".lookup_btn", cp_container).hide().removeClass('btn-block');
  $(".add_recipient", cp_container).show();
  $(".contact_point").prop('disabled', true);
  $(".add_recipient").show();
  $(".resource_container", cp_container).show();
};

RecipientsForm.prototype.add_recipient = function(e){
  if(!this.org_resource_picker.complete()) {return false;  }

  var has_errors = false;
  var resources = this.org_resource_picker.resources();

  $.each(resources, function(index){
    var recipient = new Recipient({
      sms: this.get_phone("sms"),
      voice: this.get_phone("voice"),
      email: this.get_email(),
      business_name: this.org_resource_picker.org_name(),
      resource_name: resources[index]
    });

    if(this.recipients[recipient.key] || this.new_recipients[recipient.key]){
      has_errors = true;
      alert("You already added: "+ recipient.title());
      return false;
    }
    else
      this.new_recipients[recipient.key] = recipient;
  }.bind(this));

  if(has_errors)
    this.new_recipients = {};
  else
    this.submit_recipient(this.org_resource_picker.prepare_request(this.new_recipients));
};

RecipientsForm.prototype.submit_recipient = function(recipient){
  $.ajax({
    url: "/recipients",
    method: "post",
    data: {recipient: recipient},
    success: function(response){
      this.new_recipients = {};

      $.each(response, function(index){
        var recipient = response[index];
        this.new_recipients[recipient.key] = new Recipient(recipient);
      }.bind(this));

      $.extend(this.recipients, this.new_recipients);
      this.parent.append_recipients($.extend({}, this.new_recipients));
      this.close();
    }.bind(this),
    error: function(){
      this.new_recipients = {};
    }.bind(this)
  });
};

RecipientsForm.prototype.cancel_recipient = function(){
  this.clean();
  $(".resource_container", this.container).hide();
  $(".lookup_btn", this.container).show();
  $(".add_recipient").hide();
  this.goto_page(1);
};

RecipientsForm.prototype.remove = function(recipient){
  delete this.recipients[recipient];
  delete this.new_recipients[recipient];
};

RecipientsForm.prototype.get_email = function(){
  if(this.add_flow != 2) return "";
  return this.get_cp(this.email_container);
}

RecipientsForm.prototype.get_cp = function(cp_container){
  return $(".contact_point", cp_container).val();
};

RecipientsForm.prototype.get_phone = function(contact_point){
  if(this.add_flow != 1) return "";

  if($(".contact_using_ckbox").is(':checked') || (contact_point=='voice'))
    return this.get_cp(this.phone_container);
  else
    return "";
}

RecipientsForm.prototype.clean = function(){
  this.new_recipients = {};
  $(".error_label").hide();
  $(".contact_point", this.container).val("");
  $(".contact_point").prop('disabled', false);
  $('.contact_using_ckbox').prop('checked',false);
  if(this.org_resource_picker){ this.org_resource_picker.clear(); }
};

RecipientsForm.prototype.show = function(){
  this.goto_page(1);
};

RecipientsForm.prototype.hide = function(){
  $(".recipients_page_nav").hide();
};

RecipientsForm.prototype.close = function(){
  this.cancel_recipient();
  this.hide();
  this.new_recipients = {};
  if (this.after_add_with_contact)
    this.after_add_with_contact();
  else
    this.parent.goto_page(2);
};

RecipientsForm.prototype.has_recipients = function(){
  return Object.keys(this.recipients).length > 0;
};

RecipientsForm.prototype.back_to_list = function() {
  this.cancel_recipient();
  if (this.after_add_with_contact)
    this.after_add_with_contact();
  else
    this.goto_page(1);
};

RecipientsForm.prototype.init_with_phone = function(phone) {
  this.init_with_contact();
  var denormalized_phone = '(' + phone.substr(1, 3) + ') ' + phone.substr(4, 3) + '-' + phone.substr(7, 4);
  $('.contact_point', this.phone_container).val(denormalized_phone);
  this.goto_page(2);
  this.add_as_phone();
  this.org_resource_picker.select.selectized_parent.focus();
};

RecipientsForm.prototype.init_with_email = function(email) {
  this.init_with_contact();
  $('.contact_point', this.email_container).val(email);
  this.goto_page(3);
  this.add_as_email();
  this.org_resource_picker.select.selectized_parent.focus();
};

RecipientsForm.prototype.init_with_org_uid = function(org_uid, org_name) {
  this.init_with_contact();
  this.goto_add_by_org();

  var org_select = this.org_resource_picker.select.selectized_parent;
  org_select.addOption( { uniqueid: org_uid, name: org_name });
  org_select.setValue(org_uid);
};

RecipientsForm.prototype.init_with_contact = function() {
  this.show();
  this.after_add_with_contact = function() {
    this.hide();
    this.parent.goto_page(1);
    this.clear_contact_hooks();
  };
};

RecipientsForm.prototype.goto_add_by_org = function() {
  this.goto_page(4);
  this.show_resource_picker(null, '.organization', true);
  this.org_resource_picker.select.selectized_parent.focus();
};

RecipientsForm.prototype.clear_contact_hooks = function() {
  this.after_add_with_contact = null;
};

RecipientsForm.prototype.org_lookup_by_id_url = function(){
  return $('#recipients_form_page_4').data('orgLookupUrl');
};

RecipientsForm.prototype.org_lookup_by_cp_url = function(){
  return $('#recipients_form_page_2').data('orgLookupUrl');
};
