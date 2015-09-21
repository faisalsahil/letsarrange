function LengthTimePicker(picker, control, input){
  var subtitles = {hours: "Select hours then minutes", minutes:"Select minutes, or go back to hours"}
  var timeHelper = new TimeHelper();
  this.length_picker = new Picker(picker,control,input,timeHelper, subtitles,this);
  this.setup();
}

LengthTimePicker.prototype.setup = function(){
  var startDate = new Date();
  startDate.setHours(0);
  startDate.setMinutes(1);

  var initialDate = startDate.clone();
  initialDate.setHours(1);
  initialDate.setMinutes(0);

  this.length_picker.picker.datetimepicker({
    startDate: startDate,
    initialDate: initialDate,
    endDate: startDate.clone().addHours(23).addMinutes(55),
    todayHighlight: false,
    format: 'hh:ii',
    autoclose: false,
    language: 'en',
    startView: 1,
    maxView: 1
  }).on('changeDate', this.on_change_date.bind(this));

  $(".datetimepicker-hours .switch",this.length_picker.picker).css("color","white");
  $(".datetimepicker-hours .switch",this.length_picker.picker).css("font-size","0px");
  this.length_picker.bind_events();
};

LengthTimePicker.prototype.on_change_date = function(ev, triggered_date) {
  var new_date = new Date((ev.date || triggered_date).getTime());
  new_date.add(new_date.getTimezoneOffset()/60).hours();
  this.length_picker.update_fields(new_date);
};

LengthTimePicker.prototype.get_initial_date = function(){
  var date = new Date();
  date.setSeconds(0);
  date.setMinutes(0);
  date.setHours(1);
  return date;
};

LengthTimePicker.prototype.get_length = function(){
  var date = this.length_picker.control.val().split(":");

  if(date.length == 2)
    return {hours: date[0], minutes: date[1]}
  else 
    return {hours: 0, minutes: 0}
};

LengthTimePicker.prototype.subscribeToChange = function(callback){
  this.length_picker.picker.on("changeDate", callback);
};

LengthTimePicker.prototype.date_is_valid = function(date){
  return true;
};

LengthTimePicker.prototype.get_date = function(date){
  return Date.parse(date);
};

LengthTimePicker.prototype.format = function(date){
  return date.toString("H:mm");
};

LengthTimePicker.prototype.reset_to = function(reset_val, picker){
  var reset_to_date = Date.today();
  hour_minutes = reset_val.split(':');
  reset_to_date.setHours(hour_minutes[0], hour_minutes[1]);
  picker.set_date(reset_to_date);
  reset_to_date.add(- reset_to_date.getTimezoneOffset() / 60).hours();
  picker.picker.trigger('changeDate', reset_to_date);
}
