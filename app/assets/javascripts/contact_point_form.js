function ContactPointForm(container){
  this.container = container;

  $(".as_sms", this.container).click(this.add_as_sms.bind(this));
  $(".as_voice",this.container).click(this.add_as_voice.bind(this));
  $(".as_both",this.container).click(this.add_as_both.bind(this));
  $(".as_email",this.container).click(this.add_as_email.bind(this));
  $(".modal",this.container).on("show.bs.modal", this.reset.bind(this));
  $(".cancel_btn", this.container).click(this.cancel.bind(this));
  $(".contact_point.email", this.container).keypress(function(e){
    if( e.which == 13) this.add_as_email();
  }.bind(this));
}

ContactPointForm.prototype.subscribe_to_close = function(callback){
  $(this.container).on("hidden.bs.modal", function(){
    var val = this.sms || this.voice || this.email;
    if(val) callback(val, (this.sms)? 'sms' : (this.voice)? 'voice' : 'email');
  }.bind(this));
};

ContactPointForm.prototype.get_contact_point = function(){
  return {voice: this.voice, sms: this.sms, email: this.email};
};

ContactPointForm.prototype.add_as_email = function(){
  var email = $(".contact_point.email", this.container).val();
  var validations = new Validations();
  
  if(!validations.valid_email(email) || email == ""){
    $(".contact_point.email").effect("highlight", {}, 5000);
  }else{
    this.email = email;
    this.close();
  } 
};

ContactPointForm.prototype.add_as_sms = function(){
  this.add_as_phone(function(number){
    this.sms = number;
  }.bind(this));
};

ContactPointForm.prototype.add_as_voice = function(){
  this.add_as_phone(function(number){
    this.voice = number;
  }.bind(this));
};

ContactPointForm.prototype.add_as_both = function(){
  this.add_as_phone(function(number){
    this.sms = number;
    this.voice = number;
  }.bind(this));
};

ContactPointForm.prototype.add_as_phone = function(update_callback){
  var number = $(".contact_point.phone", this.container).val();
  
  if(this.validate_as_phone(number)){
    update_callback(number);
    this.close();
  }
};

ContactPointForm.prototype.validate_as_phone = function(number){
  var validations = new Validations();
  
  if(!validations.valid_phone(number) || number == ""){
    $(".contact_point.phone").effect("highlight", {}, 5000);
    return false;
  }else{
    return true;
  } 
};

ContactPointForm.prototype.cancel = function(){
  this.reset();
  this.close();
}

ContactPointForm.prototype.reset = function(){
  $("input", this.container).val("");
  this.unblock();
  this.sms = null;
  this.voice = null;
  this.email = null;
};

ContactPointForm.prototype.close = function(){
  $(".modal").modal("hide");
};

ContactPointForm.prototype.unblock = function(){
  $("a", this.container).prop('disabled', false);
};

ContactPointForm.prototype.block = function(){
  $("a", this.container).prop('disabled', true);
};
