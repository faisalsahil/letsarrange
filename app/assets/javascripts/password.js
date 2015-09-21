var PasswordsController = Paloma.controller('Passwords');

PasswordsController.prototype.new = function(){
    new ContactPointForm($("#contact_point_modals")).subscribe_to_close(submit_password_reset);
};

var submit_password_reset = function(cp_description, cp_type) {
    var form = $('#new_user');
    form.append('<input type="hidden" name="user[contact_point_for_reset][description]" value="' + cp_description + '" />');
    form.append('<input type="hidden" name="user[contact_point_for_reset][type]" value="' + cp_type + '" />');
    form.submit();
};