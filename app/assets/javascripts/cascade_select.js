function CascadeSelect(parent_selector, child_selector, extra_options, extra_child_options){
  this.child_selector = child_selector;

  if (!extra_options) extra_options = {};
  if (!extra_child_options) extra_child_options = {};

  var default_options = {
    plugins: ['restore_on_backspace'],
    persist: true,
    valueField: 'uniqueid',
    labelField: 'name',
    searchField: ['name'],
    sortField: 'name',
    createOnBlur: true,
    create: true,
    maxItems: 1,

    onChange: function(org_id) {
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
            //results.push({name: "anyone"});
            resource_selectize.open();
            callback(results);
          }
        })
      });
    }.bind(this)
  };

  var select_org = $(parent_selector).selectize($.extend({}, default_options, extra_options));
  var default_child_options = {
    plugins: ['restore_on_backspace','remove_button'],
    delimiter: ',',
    persist: true,
    searchField: ["name"],
    labelField: "name",
    createOnBlur: true,
    valueField: "name",

    create: function(input) {
      return {
        id: input,
        name: input
      }
    }
  }
  var select_resource = $(child_selector).selectize($.extend({}, default_child_options, extra_child_options));

  this.selectized_parent = select_org[0].selectize;
  this.selectized_child = select_resource[0].selectize;
  this.selectized_child.disable();
}

CascadeSelect.prototype.complete = function(){
  org = this.selectized_parent.getValue();
  resource = this.selectized_child.getValue();
  if (resource == ""){
    this.add_anyone_results();
    resource = this.selectized_child.getValue();
  }
  return org != "" && resource != "";
};

CascadeSelect.prototype.clear = function(){
  this.selectized_parent.clearOptions();
  this.selectized_child.clearOptions();
};

CascadeSelect.prototype.org_name = function(){
  return !!this.org_uniqueid() ? this.selectized_parent.options[this.org_uniqueid()].name : ''
};

CascadeSelect.prototype.org_uniqueid = function(){
  return this.selectized_parent.getValue();
};

CascadeSelect.prototype.resources = function(){
  return this.selectized_child.getValue().split(',');
};

CascadeSelect.prototype.add_anyone_results = function(){
  var anyone_option = {name: "anyone"};
  this.selectized_child.addOption(anyone_option);
  this.selectized_child.addItem(anyone_option.name);
  return [anyone_option];
}
