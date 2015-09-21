function ResourceSelect(resources){
  var select_resource, $select_resource;

  $select_resource = $("#line_item_organization_resource_attributes_name").selectize({
    plugins: ['restore_on_backspace'],
    delimiter: ',',
    persist: true,
    searchField: ["name"],
    labelField: "name",
    valueField: "name",
    maxItems: 1,
    options: resources,

    create: function(input) {
        return {
            name: input
        }
    },
  });
  
  select_resource = $select_resource[0].selectize;
  select_resource.options["anyone"] = { name: "anyone"};
}