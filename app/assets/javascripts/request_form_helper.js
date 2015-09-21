function RequestsFormHelper(container,parent){
  this.container = container;
  this.request = new LineItemCustomize();
  this.parent = parent;
  this.length_pickers = {};
  this.date_pickers = {};
}

RequestsFormHelper.prototype.goto_page = function(page_number){
  $(".page", this.container).hide();
  $(".request_page_nav").hide();

  $("#request_page_"+page_number+"_nav").show();
  $("#request_page_"+page_number).toggle();
};

RequestsFormHelper.prototype.back_from_recipient = function(){
  $(".new_resource").hide();
  this.goto_page(2);
};

RequestsFormHelper.prototype.append_recipients = function(recipients){
  $("#request_page_2 .help").hide();

  Object.keys(recipients).forEach(function (key) {
    var r = recipients[key];
    $("#lineitems_recipients_list", this.container).prepend(this.recipient_template(r));
    this.current_recipient = r;
    $(".add_fields", this.container).trigger("click");
  }.bind(this));
};

RequestsFormHelper.prototype.recipient_template = function(recipient){
  // TODO: use Handlebars to share templates between JS logic (frontend) and Rails views (backend)
  // Rose: move buttons to a new row
  return "<li id='" + recipient.key + "' class='recipient_" + recipient.organization_resource_id + " list-group-item'><p class='recipient-title'>" + recipient.title() + "</p>" +
      "<a href='javascript:void(0)' class='delete_recipient btn btn-primary-muted' data-confirm-text='Are you sure you want to delete " + recipient.title() + "?'>" +
      "<i class='fa fa-times'></i> Delete</a> " +
      "<a href='javascript:void(0)' class='goto_recipient btn btn-default'><i class='fa fa-pencil-square-o'></i> Customize</a>" +
      "</li>";
};

RequestsFormHelper.prototype.prepare_line_ids = function(line_item,id){
  this.set_picker_id("length",line_item,id);
  this.set_picker_id("earliest_start",line_item,id);
  this.set_picker_id("ideal_start",line_item,id);
  this.set_picker_id("finish_by",line_item,id);
};

RequestsFormHelper.prototype.track_modifications = function(line){
  this.request.track_modifications(line);
};

RequestsFormHelper.prototype.cancel_modifications = function(line){
  this.request.cancel_modifications(line);
  this.restore_pickers(line);
};

RequestsFormHelper.prototype.track_field = function(line,field){
  this.request.track_field(line,field,this.request.get_values());
};

RequestsFormHelper.prototype.set_picker_id = function(picker,line,id){
  $(".picker_container."+picker,line).attr("id",id+"_"+picker+"_container");
  $(".modal."+picker,line).attr("id",id+"_"+picker+"_modal");
  $(".change_btn."+picker,line).attr("data-target","#"+id+"_"+picker+"_modal");
};

RequestsFormHelper.prototype.populate_line_item = function(line_item, recipient){
  var defaults = this.request.get_values();
  var contact_name = "";

  //Metadata
  $(".organization_resource_id",line_item).val(recipient.organization_resource_id);
  $(".created_for_id", line_item).val(recipient.created_for_id);

  $(".earliest_start_input",line_item).val(defaults.earliest_start);
  $(".finish_by_input",line_item).val(defaults.finish_by);
  $(".ideal_start_input",line_item).val(defaults.ideal_start);
  $(".length_input",line_item).val(defaults.length);
  $(".description",line_item).val(defaults.description);
  $(".location",line_item).val(defaults.location);
  $(".offer",line_item).val(defaults.offer);
  $(".comment",line_item).val(defaults.comment);


  this.turn_on_pickers(line_item);
};

RequestsFormHelper.prototype.turn_on_pickers = function(line_item){
  var key = line_item.attr('id');

  this.length_pickers[key] = new LengthTimePicker(
    $('.length_picker', line_item),
    $(".length_control", line_item),
    $('.length_input', line_item)
  );

 this.date_pickers[key] = new CompoundDatePicker({
    start: $(".earliest_start_picker",line_item),
    ideal:  $(".ideal_start_picker",line_item),
    finish: $(".finish_by_picker",line_item),
    start_control: $(".earliest_start_control",line_item),
    ideal_control: $(".ideal_start_control",line_item),
    finish_control: $(".finish_by_control",line_item),
    start_input: $(".earliest_start_input",line_item),
    ideal_input: $(".ideal_start_input",line_item),
    finish_input: $(".finish_by_input",line_item),
    length: this.length_pickers[key],
    start_view: 1,
    ideal_view: 1,
    finish_view: 1,
    start_max_view: 2,
    ideal_max_view: 2,
    finish_max_view: 2,
    has_default_values: false,
    tmz: $('#request_time_zone').val()
  });
};

RequestsFormHelper.prototype.restore_pickers = function(line){
  var key = line.attr('id');
  // restore length picker values
  this.length_pickers[key].length_picker.reset_button();
  // restore earliest start picker values
  if($(".earliest_start_input",line).val() != ''){
    var new_earliest_start = this.date_pickers[key].tmz.local_equivalent($(".earliest_start_input",line).val());
    this.date_pickers[key].start_picker.update_fields(new_earliest_start);
    this.date_pickers[key].start_picker.set_date(new_earliest_start);
  }
  // restore finish by picker values
  if($(".finish_by_input",line).val() != ''){
    var new_finish_by = this.date_pickers[key].tmz.local_equivalent($(".finish_by_input",line).val());
    this.date_pickers[key].finish_picker.update_fields(new_finish_by);
    this.date_pickers[key].finish_picker.set_date(new_finish_by);
  }
  // restore ideal start picker values
  if($(".ideal_start_input",line).val() != ''){
    var new_ideal = this.date_pickers[key].tmz.local_equivalent($(".ideal_start_input",line).val());
    this.date_pickers[key].ideal_picker.update_fields(new_ideal);
    this.date_pickers[key].ideal_picker.set_date(new_ideal);
  }
};