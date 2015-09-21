var SessionsController = Paloma.controller('Sessions');

SessionsController.prototype.new = function(){
  SignInManager.setup_sign_in_up_links();

  $("#start_now_link").on('click', function(){
    $(".landing-body").hide();
    $("#signin-form").show();
  });

  $("#signin-form").on('click', "#back_from_signin",function(){
    $("#signin-form").hide();
    $(".landing-body").show();
  });

  $("#learn_more_link").on('click', function(){
    $(".site-wrapper").hide();

    tutorial = $("#tutorial").owlCarousel({
        slideSpeed : 300,
        paginationSpeed : 400,
        singleItem:true,
        responsive: true
    });

    $(".container").show();
  });

  $(".learn_more_next_link").click(function(){
    var tutorial = $("#tutorial").data('owlCarousel');
    tutorial.next();
  });

  $(".back_from_landing").click(function(){
    $(".container").hide();
    $(".site-wrapper").show();

    var tutorial = $("#tutorial").data('owlCarousel');
    tutorial.goTo(0);
  });
};