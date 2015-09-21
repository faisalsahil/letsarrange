function CompoundDatePicker(options){
	var dateTimeHelper = new DateTimeHelper();

  var subtitles = {days: "Select day first", hours: "Select hours then minutes. Click the date to change it", minutes:"Select minutes, or go back to hours"}
	this.start_picker = new Picker(options["start"],options["start_control"],options["start_input"], dateTimeHelper,subtitles,this);
  this.ideal_picker = new Picker(options["ideal"],options["ideal_control"],options["ideal_input"],dateTimeHelper,subtitles,this);
	this.finish_picker = new Picker(options["finish"],options["finish_control"],options["finish_input"],dateTimeHelper,subtitles,this);

	this.tmz = new TimeZoneWrapper(options["tmz"]);
  this.start_date = this.tmz.ceiled_now();
	this.length_picker = options["length"];
	this.options = options;
	this.setup();
  this.timeHelper = new TimeHelper();
}

CompoundDatePicker.prototype.setup = function(){
	var date_contrains = {startDate: this.start_date,endDate: this.start_date.clone().add(28).days() },
			default_options = this.default_options();

	var start_options = this.picker_options("start");
	 		ideal_options = this.picker_options("ideal"),
			finish_options = this.picker_options("finish");

	if(!this.options["has_default_values"]){
		$.extend(start_options,date_contrains);
		$.extend(ideal_options,date_contrains);
		$.extend(finish_options,date_contrains);
	}

	$.extend(start_options,default_options);
	$.extend(ideal_options,default_options);
	$.extend(finish_options,default_options);

	this.start = this.start_picker.picker.datetimepicker(start_options).on('changeDate', function(ev) {
		start_date = this.move_date_to_tmz(ev);
	  this.rules_for_start(start_date);
	}.bind(this));

  
	this.ideal = this.ideal_picker.picker.datetimepicker(ideal_options).on('changeDate', function(ev) {
	   ideal_date = this.move_date_to_tmz(ev);
		 this.rules_for_ideal(ideal_date);	
	}.bind(this));

	this.finish = this.finish_picker.picker.datetimepicker(finish_options).on('changeDate', function(ev) {
		  finish_date = this.move_date_to_tmz(ev);
		  this.rules_for_finish(finish_date);
	}.bind(this));
  

	this.length_picker.subscribeToChange(this.trigger_rules.bind(this));

	this.start_picker.bind_events();
	this.ideal_picker.bind_events();
	this.finish_picker.bind_events();

	this.length_picker.length_picker.subscribeToClear(this.clear.bind(this));
	this.start_picker.subscribeToClear(this.clear.bind(this));
  this.ideal_picker.subscribeToClear(this.clear.bind(this));
	this.finish_picker.subscribeToClear(this.clear.bind(this));

	this.start_picker.subscribeToOpen(this.trigger_rules.bind(this));
	this.ideal_picker.subscribeToOpen(this.trigger_rules.bind(this));
	this.finish_picker.subscribeToOpen(this.trigger_rules.bind(this));

	if(this.options["edit_mode"]){
		this.trigger_rules();
	}
};

CompoundDatePicker.prototype.get_initial_date = function(){
	var date = this.tmz.ceiled_now();
	return date;
};

CompoundDatePicker.prototype.clear = function(){
	this.trigger_rules();
};

CompoundDatePicker.prototype.trigger_rules = function(){
	this.rules(this.start_picker.get_date(),
								this.ideal_picker.get_date(),
								this.finish_picker.get_date());
};

CompoundDatePicker.prototype.rules_for_start = function(start){
	var finish = this.finish_picker.get_date();
	var ideal = this.ideal_picker.get_date();
	this.rules(start,ideal, finish);
	this.start_picker.update_fields(start);
};

CompoundDatePicker.prototype.rules_for_ideal = function(ideal){
	var start = this.start_picker.get_date();
	var finish = this.finish_picker.get_date();
	this.rules(start,ideal, finish);
	this.ideal_picker.update_fields(ideal);
};

CompoundDatePicker.prototype.rules_for_finish = function(finish){
	var start = this.start_picker.get_date();
	var ideal = this.ideal_picker.get_date();
  this.finish_picker.update_fields(finish);
  this.rules(start,ideal, finish);
};

CompoundDatePicker.prototype.rules = function(start,ideal,finish){
  var baseline, top;
	var length = this.length_picker.get_length();
	var now = this.tmz.ceiled_now();

	if (!start){
		start = now.clone();

    if(start.getMinutes() >= 55 && start.getMinutes() << 59 ){
      start = this.timeHelper.move_to_next_hour(start);
    } 
  }
	else
    if (start.isBefore(now)) {
      start = now.clone();
      // CAUTION: the following line was causing an infinite loop so I'm commenting and replacing it by the logic expected
      // this.reset_to(start, this.start_picker);
      this.start_picker.set_date(start);
    }

  if (ideal && ideal.isBefore(start)) {
    this.ideal_picker.update_fields(start);
    ideal = start;
  }
	
	baseline = (ideal)? ideal.clone() : start.clone();

	baseline.addHours(length.hours).addMinutes(length.minutes);
	
	this.start_picker.set_start_date(now); 
	this.ideal_picker.set_start_date(start);
	this.finish_picker.set_start_date(baseline);

  if (finish) {
		top = finish.clone().addHours(-length.hours).addMinutes(-length.minutes);
		if (finish.isBefore(baseline)) {
			this.finish_picker.reset();
			top = start.clone().addDays(28);
		}
	
		if (top && ideal && ideal.isAfter(top))
      this.ideal_picker.reset();
	}
  else{
    top = start.clone().addDays(28);
  }

	this.ideal_picker.set_end_date(top);
};

CompoundDatePicker.prototype.default_options = function() {
	return {
		format: 'yyyy-mm-dd hh:ii',
    showMeridian: true,
		autoclose: true,
		language: 'en',
    pickerPosition: "bottom-left"
	};
};

CompoundDatePicker.prototype.picker_options = function(picker){
 	return {startView: this.options[picker+"_view"],maxView: this.options[picker+"_max_view"]};
};

CompoundDatePicker.prototype.move_date_to_tmz = function(ev) {
	var new_date = new Date(ev.date.getTime());
	new_date.add(new_date.getTimezoneOffset()/60).hours();
	new_date.setSeconds(0);
	return new_date;
};

CompoundDatePicker.prototype.date_is_valid = function(date){
  var now = this.tmz.ceiled_now();
  return !date.isBefore(now);
};

CompoundDatePicker.prototype.get_date = function(date){
	return this.tmz.local_equivalent(date);
};

CompoundDatePicker.prototype.format = function(date){
  return this.tmz.to_s(date);
};

CompoundDatePicker.prototype.reset_to = function(reset_val, picker){
  var reset_to_date = new Date(reset_val);
  if (moment().isAfter(reset_to_date)) reset_to_date = new TimeHelper().ceiled_now();
  picker.set_date(reset_to_date);
  if (picker.input.attr('id') == 'line_item_earliest_start')
    this.rules_for_start(reset_to_date);
  else if (picker.input.attr('id') == 'line_item_ideal_start')
    this.rules_for_ideal(reset_to_date);
  else
    this.rules_for_finish(reset_to_date);
}
