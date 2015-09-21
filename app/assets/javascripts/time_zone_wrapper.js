function TimeZoneWrapper(tmz){
  this.tmz = tmz;
}

TimeZoneWrapper.prototype.now = function(){
  var now_in_tmz = moment().tz(this.tmz);
  var today = new Date();
  today.setHours(now_in_tmz.hours());
  today.setDate(now_in_tmz.date());
  today.setMonth(now_in_tmz.month());
  return today;
};

TimeZoneWrapper.prototype.ceiled_now = function(){
  var five_minutes = 5 * 60 * 1000;
  return new Date(this.now().getTime() - this.now().getTime() % five_minutes + five_minutes);
};

TimeZoneWrapper.prototype.to_s = function(date){
  return moment(date).tz(this.tmz).hours(date.getHours()).day(date.getDay()).format();
};

TimeZoneWrapper.prototype.local_equivalent = function(date_string){
  var m = moment(date_string).tz(this.tmz);
  var equivalent = m.toDate();
  equivalent.setHours(m.hours());
  equivalent.setDate(m.date());
  equivalent.setMonth(m.month());
  return equivalent;
};