var RequestsController = Paloma.controller('Requests');

RequestsController.prototype.new = function(){
  $('#request_time_zone').set_timezone();
  // if detected time-zone does not match with values in the dropdown, then we set it default to PST
  if (!$('#request_time_zone').val())
    $('#request_time_zone').val('America/Phoenix');

  var length_picker = new LengthTimePicker(
    $(".length_picker", "#request_length_picker_container"),
    $(".length_control", "#request_length_picker_container"),
    $('#request_length')
  );

  var compoundDatePicker = new CompoundDatePicker({
    start: $(".earliest_start_picker",'#request_earliest_start_container'),
    ideal:  $(".ideal_start_picker","#request_ideal_start_container"),
    finish: $(".finish_by_picker",'#request_finish_by_container'),
    start_control: $(".earliest_start_control",'#request_earliest_start_container'),
    ideal_control: $(".ideal_start_control",'#request_ideal_start_container'),
    finish_control: $(".finish_by_control",'#request_finish_by_container'),
    start_input: $("#request_earliest_start"),
    ideal_input: $("#request_ideal_start"),
    finish_input: $("#request_finish_by"),
    length: length_picker,
    start_view: 1,
    ideal_view: 1,
    finish_view: 1,
    start_max_view: 2,
    ideal_max_view: 2,
    finish_max_view: 2,
    has_default_values: false,
    tmz: $('#request_time_zone').val()
  });

  var formHelper = new RequestsFormHelper($("#new_request_container"));
  var recipientForm = new RecipientsForm($("#recipients_form"),formHelper);

  // setup 'request option' page
  RequestOptionsPageManager.setup_share_contact_details_setting();
  if (this.params['logged_in'])
    RequestOptionsPageManager.setup_request_made_for_setting();

  $(".request_page_1.next_page").click(function(){
    formHelper.goto_page(5);
  });

  $(".request_page_2.next_page").click(function(){
    formHelper.goto_page(3);
    // recipientForm.show();
  });

  $(".request_page_2.back_page").click(function(){
    formHelper.goto_page(1);
  });

  $("#request_page_5 .back_page").click(function(){
    formHelper.goto_page(1);
  });

  $("#request_page_5 .next_page").click(function(){
    formHelper.goto_page(2);
  });

  $("#request_page_5 .leave_options_page").click(function(){
    var orgCreator = RequestOptionsPageManager.orgCreator;
    if (!!orgCreator)
      orgCreator.submit_org_with_resource();
  });

  $("ul.subnav li a").click(function(){
    formHelper.goto_page($(this).data('back-to-page'));
  });

  recipientForm.subscribe_to_back(function(){
    formHelper.goto_page(2);
  });

  recipientForm.subscribe_to_back_global(function(){
    formHelper.goto_page(2);
  });

  $(".request_page_4.back_page").click(function(){
    formHelper.back_from_recipient();
  });

  $(".request_page_1.options_page").click(function(){
    formHelper.goto_page(5);
  });

  $(".request_page_2.options_page").click(function(){
    formHelper.goto_page(5);
  });

  $("#new_request_container").on("click",".goto_recipient",function(){
    var page = $(this).parent().attr("class").split(" ")[0];
    page = $(".new_resource."+page);
    page.show();
    $("p#recipient_customize_title").text('Customize ' + $(this).closest('.list-group-item').find('.recipient-title').text());
    formHelper.track_modifications(page);
    formHelper.goto_page(4);
  });

  $("#new_request_container").on("click", ".delete_recipient",function(){
    if(confirm($(this).data('confirm-text'))){
      var page = $(this).parent().attr("id");
      recipientForm.remove(page);
      $(".new_resource."+$(this).parent().attr("class").split(" ")[0]).remove();
      $(this).parent().remove();

      if($("#lineitems_recipients_list li").size() == 0){
        $(".send_request_btn").parent().hide();
      }
    }
  });

  $("#new_request_container").on("click",".customize_recipient", function(){
    formHelper.back_from_recipient();
  });

  $("#new_request_container").on("click",".cancel_customize_recipient", function(){
    var page = $(this).parents('.new_resource').attr("class").split(" ")[2];
    page = $(".new_resource."+page);
    formHelper.cancel_modifications(page);
    formHelper.back_from_recipient();
  });

  // toggle hide/show 'Share details' panel based on Message Branding selection
  $("#new_request_container").on("click", "#request_message_branding", function(){
    $(".share_cp_details_container").toggle(!this.checked);
    if (this.checked){
      $("input[name='request[contact_point_id]'][value='']").prop('checked',true);
    }
  });

  //Change ids of each line_item after insertion.
  $(document).on("cocoon:after-insert", function(e,insertedItem){
    var last_line_item = insertedItem.prev();
    var new_id = 1;

    if(last_line_item.size() >0)
      new_id = parseInt(last_line_item.attr("id").split("_")[1])+1;

    insertedItem.attr("id","line_"+new_id);
    insertedItem.addClass("recipient_"+formHelper.current_recipient.organization_resource_id);
    formHelper.prepare_line_ids(insertedItem,new_id);
    formHelper.populate_line_item(insertedItem, formHelper.current_recipient);
    $(".send_request_btn").parent().show();
  });

  $("#request_page_1").on("blur", "input", function(){
    var field = $(this).attr("class").split(" ").pop();
    if(field.indexOf("control") == -1){
      $(".new_resource .field_container:not(.has-changed) > .request_line_items_"+field+" input").val($(this).val());
    }
  });

  $("#request_page_1").on("hidden.bs.modal", ".modal", function(){
    $("#request_page_1 .modal").each(function(){
      var field = $(this).attr("class").split(" ")[1];
      var picker_value = $(this).siblings(".form-control").val();
      var input_value = $(this).siblings(":not(.form-control)").val()

      $(".new_resource .field_container:not(.has-changed) > ."+field+" ."+field+"_control").val(picker_value);
      $(".new_resource .field_container:not(.has-changed) > ."+field+" ."+field+"_input").val(input_value);
    });
  });

  $("#new_request_container").on("blur", ".new_resource input", function(){
    var field = $(this).attr("class").split(" ").pop();

    if(field.indexOf("control") == -1){
      formHelper.track_field($(this).parents(".new_resource"), field);
    }
  });

  $("#new_request_container").on("hidden.bs.modal", ".new_resource .modal", function(){
    var field = $(this).attr("class").split(" ")[1];
    formHelper.track_field($(this).parents(".new_resource"), field);
  });

  $("a#btn_cancel_request").click(function(e){
    if(recipientForm.has_recipients()){
      if(!confirm("You are about to cancel this request, Are you sure?")){
        e.preventDefault();
      }
    }
  });

  $('#request_time_zone').change(function(){
    compoundDatePicker.tmz = new TimeZoneWrapper(this.value);
    compoundDatePicker.trigger_rules(); // isn't this the same? => compoundDatePicker.clear();
    // update current values if any
    var earliest_start = $('#request_earliest_start').val(),
        finish_by = $('#request_finish_by').val(),
        ideal_start = $('#request_ideal_start').val();
    if(earliest_start != ''){
      var new_earliest = compoundDatePicker.tmz.local_equivalent(earliest_start);
      compoundDatePicker.start_picker.update_fields(new_earliest);
      compoundDatePicker.start_picker.set_date(new_earliest);
    };
    if(finish_by != ''){
      var new_finish = compoundDatePicker.tmz.local_equivalent(finish_by);
      compoundDatePicker.finish_picker.update_fields(new_finish);
      compoundDatePicker.finish_picker.set_date(new_finish);
    }
    if(ideal_start != ''){
      var new_ideal = compoundDatePicker.tmz.local_equivalent(ideal_start);
      compoundDatePicker.ideal_picker.update_fields(new_ideal);
      compoundDatePicker.ideal_picker.set_date(new_ideal);
    }
  });

  autoload_contact_info(formHelper, recipientForm);
};

var autoload_contact_info = function(form_helper, recipient_form) {
  var params = query_params();
  var phone = params['phone'];
  var email = params['email'];
  var org_uid = params['ouid'];
  if (phone || email || org_uid) {
    form_helper.goto_page(3);
    if (phone)
      recipient_form.init_with_phone(decodeURIComponent(phone));
    else if (email)
      recipient_form.init_with_email(decodeURIComponent(email));
    else
      recipient_form.init_with_org_uid(decodeURIComponent(org_uid), decodeURIComponent(params['oname'].replace(/\+/g, ' ')));
  }
};