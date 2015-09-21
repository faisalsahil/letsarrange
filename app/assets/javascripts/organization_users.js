var UsersController = Paloma.controller('Organizations/Users');

UsersController.prototype.new = function(){

  var $select_user,
      org_id = this.params['org_id'];

  $select_user = $(".user_uniqueid").selectize({
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
        url: '/users',
        type: 'GET',
        dataType: 'json',
        data: { q: query, org_id: org_id },
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