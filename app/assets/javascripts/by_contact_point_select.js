function ByContactPointSelect(org_lookup_url, parent_selector, child_selector, contact_point){
  this.resource_data = { contact_point: contact_point };

  this.select = new CascadeSelect(parent_selector, child_selector);
  this.selectized_parent = this.select.selectized_parent;

  this.selectized_parent.load(function(callback){
    $.ajax({
      url: org_lookup_url,
      data: this.resource_data,
      success: function(results) {
        if (!results.length)
          results = this.add_no_results();
        else if (results.length == 1){
          this.selectized_parent.addOption(results[0]);
          this.selectized_parent.addItem(results[0].uniqueid);
        }
        else if (results.length > 1)
          this.selectized_parent.open();
        callback(results);
      }.bind(this)
    });
  }.bind(this));
}

ByContactPointSelect.prototype.complete = function(){
  return this.select.complete();
};

ByContactPointSelect.prototype.clear = function(){
  return this.select.clear();
};
ByContactPointSelect.prototype.org_name = function(){
  return this.select.org_name();
};
ByContactPointSelect.prototype.resources = function(){
  return this.select.resources();
};

ByContactPointSelect.prototype.org_uniqueid = function(){
  return this.select.org_uniqueid();
};

ByContactPointSelect.prototype.prepare_request = function(recipients){
  var some_recipient = {};
  var resources = $.map(recipients, function(recipient){
    some_recipient = recipient;
    return { name: recipient.resource_name, key: recipient.key };
  });

  return {
    sms: some_recipient.sms,
    voice: some_recipient.voice,
    email: some_recipient.email,
    business_name: some_recipient.business_name,
    resources: resources
  };
};

ByContactPointSelect.prototype.add_no_results = function(){
  var none_option = {uniqueid: "anyone_org_option", name: "(none)"};
  this.selectized_parent.addOption(none_option);
  this.selectized_parent.addItem(none_option.uniqueid);
  return [none_option];
};