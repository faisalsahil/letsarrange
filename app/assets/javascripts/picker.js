function Picker(picker,control,input,label_formatter,subtitles,parent){
  this.picker = picker;
  this.control = control;
  this.input = input;
  this.label_formatter = label_formatter;
  this.subtitles = subtitles;
  this.parent = parent;
  $(".modal_subtitle",this.get_container()).text(this.subtitles.hours);
}

Picker.prototype.bind_events = function(){
  $(".clear_btn", this.get_container()).click(this.reset.bind(this));
  $(".reset_btn", this.get_container()).click(this.reset_button.bind(this));
  $(".cancel_btn", this.get_container()).click(this.close.bind(this));
  $(".datetimepicker-hours .switch", this.get_container()).click(this.move_to_days.bind(this));
  $(".datetimepicker-minutes .switch", this.get_container()).click(this.move_to_hours.bind(this));
  this.picker.on("changeDay",this.move_to_hours.bind(this));  
  this.picker.on("changeHour",this.move_to_minutes.bind(this));

  $(".modal", this.get_container()).one("show.bs.modal", function(){
    $(".picker_holder", this.get_container()).html(this.picker);
    this.picker.show();
  }.bind(this));


  $(this.control).focus(function(){
    $('.modal',this.get_container()).modal('show');
  }.bind(this));

  this.run_hacks();

  var date = this.get_date();
  if(date){
    this.set_date(date);
    this.update_fields(date);
  }
};

Picker.prototype.subscribeToClear = function(callback){
  $(".clear_btn",this.get_container()).click(callback);
};

Picker.prototype.subscribeToOpen = function(callback){
  $(".modal", this.get_container()).on("show.bs.modal",  callback);
};

Picker.prototype.move_to_days = function(){
  $(".modal_subtitle",this.get_container()).text(this.subtitles.days);
};

Picker.prototype.move_to_hours = function(){
  $(".modal_subtitle",this.get_container()).text(this.subtitles.hours);
};

Picker.prototype.move_to_minutes = function(){
  $(".modal_subtitle",this.get_container()).text(this.subtitles.minutes);
  this.set_switch_title("minutes","Go back to hours");
};

Picker.prototype.close = function(){
  $(".modal").modal("hide");
};

Picker.prototype.run_hacks = function(){
  $(".next",this.picker).text(">");
  $(".prev", this.picker).text("<");
};

Picker.prototype.update_fields = function(date){
  if(!this.parent.date_is_valid(date)) return;
  this.control.val(this.label_formatter.format(date));
  this.update_input_with_change(this.parent.format(date));
  this.close();
};

Picker.prototype.reset = function(){
  this.control.val("");
  //this.input.val(null); 
  this.update_input_with_change(null);
  this.set_date(this.parent.get_initial_date());
  this.close();
};

Picker.prototype.reset_button = function(){
  var original_val = this.input.data('originalValue');
  if (original_val) this.parent.reset_to(original_val, this); else this.reset();
  this.close();
};

Picker.prototype.update_input_with_change = function(new_value){
  var prev_value = this.input.val();
  this.input.val(new_value);
  if (this.input.is(':hidden') && prev_value != this.input.val()) this.input.trigger('change');
};

Picker.prototype.set_switch_title = function(view, title){
  $(".datetimepicker-"+view+" .switch",this.get_container()).text(title);
};

Picker.prototype.get_container = function(){
  return this.control.parent();
};

Picker.prototype.set_date = function(date){
  this.picker.datetimepicker('setDate', date);
}

Picker.prototype.get_date = function(){
  if(this.input.val()=="") return;
  return this.parent.get_date(this.input.val());
};

Picker.prototype.set_start_date = function(start){
  this.picker.datetimepicker('setStartDate', start);
};


Picker.prototype.set_end_date = function(finish){
  this.picker.datetimepicker('setEndDate', finish);
};