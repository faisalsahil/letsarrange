function Recipient(attributes){
  this.update(attributes);
}

Recipient.prototype.generate_id = function(){
  var key = [];
  var cp_info = this.sms || this.voice || this.email;

  key.push(cp_info);

  if(this.business_name)
    (this.business_name == '(none)')? key.push(cp_info) : key.push(this.business_name);

  if(this.resource_name != "")
    key.push(this.resource_name);

  return key.join("_").replace(/ /g,'');
};

Recipient.prototype.title = function(){
  if (this.business_name == '(none)' || this.business_name == this.resource_name)
    return this.resource_name;
 else
    return this.resource_name + " from " + this.business_name;
};

Recipient.prototype.update = function(attributes){
  this.voice = attributes.voice;
  this.sms = attributes.sms;
  this.email = attributes.email;
  this.business_name = attributes.business_name;
  this.resource_name = attributes.resource_name;
  
  if(attributes.organization_resource_id)
    this.organization_resource_id = attributes.organization_resource_id;
  if(attributes.created_for_id)
    this.created_for_id = attributes.created_for_id;

  this.key = this.generate_id();
}