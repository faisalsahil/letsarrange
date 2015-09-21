SignInManager = {
  setup_sign_in_up_links: function(){
    var sign_in_form = $("#signin-form");
    var sign_up_form = $("#signup-form");
    sign_in_form.off('click').on("click", "#signup_link",function(){
      sign_in_form.hide();
      sign_up_form.show();
      $(this).closest('.modal').find('.modal-title').text('Sign up');
    });

    sign_up_form.off('click').on("click", "#back_from_signup",function(e){
      e.preventDefault();
      sign_up_form.hide();
      sign_in_form.show();
      $(this).closest('.modal').find('.modal-title').text('Sign in');
    });
  }
}