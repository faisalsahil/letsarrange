function OrganizationCreator(org_lookup_url, org_user_lookup_url, parent_selector, child_selector, org_user_selector){
  this.org_info_selector = $('#request_page_5 .org_info');
  this.resource_info_selector = $('#request_page_5 .resource_info');
  this.org_resource_info_selector = $('#request_page_5 .org_resource_info');

  var customCreate = function(input, callback){
    return {
      created: true,
      uniqueid: input,
      name: input
    }
  };

  var customOnChange = function(org_id){
    // default org-user name and default org-resource name
    var default_orguser_name     = $(org_user_selector).data('default-orguser-name'),
        default_orgresource_name = $(child_selector).data('default-orgresource-name');

    // loading the org-user name
    $.ajax({
      url: org_user_lookup_url,
      dataType: 'json',
      data: $.extend( { organization: {uniqueid: org_id } }, this.resource_data),
      success: function(results) {
        // calculate org-user name to set
        var value = (results.name != undefined) ? results.name : default_orguser_name;
        $(org_user_selector).val(value);
      }
    });

    // loading the resources (code inherited from CascadeSelect)
    var resource_selectize = this.selectized_child;
    resource_selectize.clearOptions();
    resource_selectize.disable();
    if (!org_id.length) return;
    resource_selectize.load(function(callback) {
      $.ajax({
        url: $('#recipients_form').data('orgResourceUrl'),
        dataType: 'json',
        data: $.extend( { organization: {uniqueid: org_id } }, this.resource_data),
        success: function(results) {
          resource_selectize.enable();
          results.push({name: "anyone"});
          var index = results.lookupByKeyValue('name',default_orgresource_name);
          if(index != '-1'){
            resource_selectize.addOption(results[index]);
            resource_selectize.addItem(results[index].name);
          }
          this.set_resource_visibility(results);
          resource_selectize.open();
          callback(results);
        }.bind(this)
      })
    }.bind(this));
  }.bind(this);

  this.cached_items = {};
  this.select = new CascadeSelect(parent_selector, child_selector, {create: customCreate, onChange: customOnChange}, { maxItems: 1 });
  this.selectized_parent = this.select.selectized_parent;
  this.selectized_child  = this.select.selectized_child;
  this.org_user_selector = org_user_selector;

  this.selectized_parent.load(function(callback){
    $.ajax({
      url: org_lookup_url,
      dataType: 'json',
      success: function(results) {
        if (results.length > 0){
          var default_org_uniqueid = $(parent_selector).data('default-org-uniqueid');
          var index = results.lookupByKeyValue('uniqueid', default_org_uniqueid);
          if (index == '-1') index = 0;
          this.selectized_parent.addOption(results[index]);
          this.selectized_parent.addItem(results[index].uniqueid);
          this.selectized_parent.open();
        }
        this.set_org_visibility(results);
        callback(results);
      }.bind(this)
    });
  }.bind(this));
};

OrganizationCreator.prototype.set_org_resource_visibility = function(results){
  if(this.resource_info_selector.css('display')!='none' || this.org_info_selector.css('display')!='none')
    this.org_resource_info_selector.show()
  else
    this.org_resource_info_selector.hide()
};

OrganizationCreator.prototype.set_org_visibility = function(results){
  // if there's only 1 org then we hide the organization info information
  if(results.length == 1)
    this.org_info_selector.hide()
  else
    this.org_info_selector.show()

  this.set_org_resource_visibility();
};

OrganizationCreator.prototype.set_resource_visibility = function(results){
  // if there's only 1 resource (except for the 'anyone' resource pushed above) then we hide the resource info information
  var total = results.filter(function(i){return i.name != 'anyone'}).length;
  if(total < 2)
    this.resource_info_selector.hide()
  else
    this.resource_info_selector.show()

  this.set_org_resource_visibility();
};

OrganizationCreator.prototype.complete = function(){
  return this.select.complete();
};

OrganizationCreator.prototype.clear = function(){
  return this.select.clear();
};

OrganizationCreator.prototype.org_name = function(){
  return this.select.org_name();
};

OrganizationCreator.prototype.resources = function(){
  return this.select.resources();
};

OrganizationCreator.prototype.org_uniqueid = function(){
  return this.select.org_uniqueid();
};

OrganizationCreator.prototype.org_created = function(){
  return !!this.org_uniqueid() ? this.select.selectized_parent.options[this.org_uniqueid()].created : false;
};

OrganizationCreator.prototype.org_user = function(){
  return $(this.org_user_selector).val();
};

OrganizationCreator.prototype.submit_org_with_resource = function(){
  // test if org was already created in current session (and it's cached in the this.cached_items instance)
  var already_created = (this.org_uniqueid() in this.cached_items);
  // test if we need to create the org in the backend
  var needs_to_create = !!this.org_created() && (!already_created);
  // data to submit
  var post_data = {
    name: this.org_name(),
    uniqueid: already_created ? this.cached_items[this.org_uniqueid()] : this.org_uniqueid(),
    resource: this.resources()[0],
    orguser: this.org_user()
  };
  if (needs_to_create) $.extend(post_data, { created: needs_to_create });

  $.ajax({
    url: "/organizations/organization_resources/find_or_create",
    method: "post",
    data: post_data,
    success: function(response){
      $('#new_request #request_organization_resource_id').val(response.id);
      if (needs_to_create)
        this.cached_items[this.org_uniqueid()] = response.org_uniqueid;
    }.bind(this),
    error: function(){
      console.log('Something failed');
    }
  });
};
