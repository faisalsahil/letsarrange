var query_cache = {};

function ByOrganizationSelect(org_lookup_url, parent_selector, child_selector){
  this.resource_data = {};
  this.select = new CascadeSelect(parent_selector, child_selector, {
    create: false,
    createOnBlur: false,
    load: function(query, callback){
      this.clearOptions();
      if (!query.length) {
        this.refreshOptions();
        callback();
      }
      else {
        if (query_cache[query])
          callback(query_cache[query]);
        else
          $.ajax({
            url: org_lookup_url,
            type: 'GET',
            dataType: 'json',
            data: { q: query },
            error: callback,
            success: function(res) {
              query_cache[query] = res;
              callback(res);
            }
          });
      }
    },
    render: {
      option: render_with_name_and_uid,
      item: render_with_name_and_uid
    }
  });
}

ByOrganizationSelect.prototype.complete = function(){
  return this.select.complete();
};

ByOrganizationSelect.prototype.clear = function(){
  return this.select.clear();
};
ByOrganizationSelect.prototype.org_name = function(){
  return this.select.org_name();
};
ByOrganizationSelect.prototype.resources = function(){
  return this.select.resources();
};

ByOrganizationSelect.prototype.org_uniqueid = function(){
  return this.select.org_uniqueid();
};

ByOrganizationSelect.prototype.prepare_request = function(recipients){
  var resources = $.map(recipients, function(recipient){
    return { name: recipient.resource_name, key: recipient.key };
  });

  return {
    organization_uniqueid: this.org_uniqueid(),
    resources: resources
  };
};

var render_with_name_and_uid = function(item, escape) {
  return '<div data-value="' + escape(item.uniqueid) + '" data-selectable="" class="option">' + escape(item.name) + ' (' + escape(item.uniqueid) + ')</div>';
};