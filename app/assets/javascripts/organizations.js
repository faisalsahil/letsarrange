var OrganizationsController = Paloma.controller('Organizations');

OrganizationsController.update_organization = function(dom_id, html) {
  $('#' + dom_id).replaceWith(html);
};