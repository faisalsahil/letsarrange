var ResourcesController = Paloma.controller('Organizations/Resources');

ResourcesController.prototype.edit = function(){

  var $select_organization,
      resource_id = this.params['resource_id'];

  $select_organization = $(".organization_uniqueid").selectize({
    plugins: ['restore_on_backspace'],
    delimiter: ',',
    persist: true,
    searchField: ["uniqueid"],
    labelField: "name",
    valueField: "uniqueid",
    maxItems: 1,
    selectOnTab: true,
    create: false,

    load: function(query, callback) {
      if (!query.length) return callback();
      $.ajax({
        url: '/organizations/trusted',
        type: 'GET',
        dataType: 'json',
        data: {resource_id: resource_id},
        error: function() {
          callback();
        },
        success: function(results) {
          callback(results);
        }
      });
    }
  });

};