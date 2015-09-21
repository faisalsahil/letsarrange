function Validations() {}

Validations.prototype.valid_email =function(email) {
  if(email.trim() == "")
    return true;

    var re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(email.trim());
};

Validations.prototype.valid_phone = function(phone){
  if(phone.trim() == "")
    return true;

  phone = phone.match(/\d+/g).join("")
  return phone.length == 10 && phone[0] != "1"
};

var query_params = function(){
  params = {};
  $.each(location.search.substring(1).split('&'), function(i, param) {
      params[param.replace(/\=.*/, '')] = param.replace(/.*=/, '');
  });
  return params;
};

// Utility like 'indexOf' to lookup objects in Arrays
if (!Array.prototype.lookupByKeyValue) {
  Array.prototype.lookupByKeyValue = function (key, value) {
    for (var i = 0; i < this.length; i++) {
      if (this[i][key] == value) {
        return i;
      }
    }
    return -1;
  };
};
