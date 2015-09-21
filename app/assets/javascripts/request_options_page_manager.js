RequestOptionsPageManager = {

  orgCreator: null,

  setup: function(){
    if (!$('.request_page_1').length) return;
    RequestOptionsPageManager.setup_share_contact_details_setting();
    RequestOptionsPageManager.setup_request_made_for_setting();
  },

  org_lookup_by_current_user_url: function(){
    return $('#request_page_5').data('orgLookupUrl');
  },

  org_users_lookup_url: function(){
    return $('#request_page_5').data('orgUsersLookupUrl');
  },

  cp_options_template: function(contact_point, checked){
    if (typeof checked === "undefined" || checked === null) { checked = false };
    var checked_str = checked ? "checked='checked'" : '';
    // TODO: use Handlebars to share templates between JS logic (frontend) and Rails views (backend)
    return "<span class='radio'>" +
           "<input " + checked_str + " class='radio_buttons optional' id='request_contact_point_id_" + contact_point.id + "' name='request[contact_point_id]' type='radio' value='" + contact_point.id + "'>" +
           "<label class='radio_buttons optional' for='request_contact_point_id_" + contact_point.id + "'>" + contact_point.description + "</label>" +
           "</span>"
  },

  setup_share_contact_details_setting: function(){
    var page = $("#request_page_5");
    var cp_lookup_url = page.data('cp-lookup-url');
    $.ajax({
      url: cp_lookup_url,
      type: 'GET',
      dataType: 'json',
      error: function(res){ console.log('Something failed') },
      success: function(res) {
        $(".share_cp_details_data_container").html("");
        $.each(res, function(index, elem){
          $(".share_cp_details_data_container").append(RequestOptionsPageManager.cp_options_template(elem,(index==0)));
        }.bind(this))
      }.bind(this)
    })
  },

  setup_request_made_for_setting: function(){
    $('#request_page_5 .org_resource_info').show();
    RequestOptionsPageManager.orgCreator = new OrganizationCreator(RequestOptionsPageManager.org_lookup_by_current_user_url(),
                                                                   RequestOptionsPageManager.org_users_lookup_url(),
                                                                   "#request_page_5 .made_for_organizations_list",
                                                                   "#request_page_5 .made_for_resources_list",
                                                                   "#request_page_5 .made_for_org_user_name");
  }
}