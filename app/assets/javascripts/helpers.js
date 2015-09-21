function DateTimeHelper() {}

DateTimeHelper.prototype.format = function(date) { 
  var date = date.toString("M/d h:mmtt");
  date = date.replace(/:00/,"") 
  return date.toLowerCase();
};

function TimeHelper() {}

TimeHelper.prototype.format = function(time){
  return time.toString('H:mm');
};

TimeHelper.prototype.ceiled_now = function(){
  var now = new Date();
  var five_minutes = 5 * 60 * 1000;
  return new Date(now.getTime() - now.getTime() % five_minutes + five_minutes);
};

TimeHelper.prototype.move_to_next_hour = function(date){
  var movedHour = date.clone();
  movedHour.addHours(1);
  movedHour.setMinutes(0);
  movedHour.setSeconds(0);
  return movedHour;
};