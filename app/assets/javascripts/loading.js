$(function() {
  setup_loading_gif();
  resize_loading_gif();
  $(window).on('resize', resize_loading_gif);
})

var setup_loading_gif = function() {
  var doc = $(document);

  doc.on('ajaxSend', function(a, b, ajax_object) {
    if (!ajax_object.url.match(/skip_loading_gif=true/)) $('#loading').show();
  });
  doc.on('ajaxComplete', function() {
    if ($.active <= 1) $('#loading').hide();
  });
};

var resize_loading_gif = function() {
  var loading = $('#loading');
  var loading_image = $('#loading_image');
  var center = (parseInt(loading.css('width')) - parseInt(loading_image.find('img').attr('width'))) / 2;
  loading_image.css('left', center.toString() + 'px');
};