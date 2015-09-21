function LineItemCustomize(){};

LineItemCustomize.prototype.set_request = function(request){
  this.request = request;
}

LineItemCustomize.prototype.get_values = function(){
  if(this.request) return this.request;

  var request = {};
  request.earliest_start = $("#request_earliest_start").val();
  request.finish_by      = $("#request_finish_by").val();
  request.ideal_start    = $("#request_ideal_start").val();
  request.length         = $("#request_length").val();
  request.description    = $("#request_description").val();
  request.location       = $("#request_location").val();
  request.offer          = $("#request_offer").val();
  request.comment        = $("#request_comment").val();

  return request;
};

LineItemCustomize.prototype.track_modifications = function(line_item){
  // set originalValue data-attribute (used by 'reset' button on pickers)
  $('.earliest_start_input, .ideal_start_input, .finish_by_input, .length_input', line_item)
    .each(function() {
      $(this).data('originalValue', $(this).val());
  });

  this.current_values = this.get_current_values(line_item);

  Object.keys(this.current_values).forEach(function(key){
    this.track_field(line_item, key, this.current_values);
  }.bind(this));
};

LineItemCustomize.prototype.track_field = function(line_item, key, request){
  var line_field = this.get_line_field(line_item,key);
  var parent     = line_field.parents(".field_container");

  if(line_field.val() != request[key]){
    parent.addClass("has-changed");
  }else{
    parent.removeClass("has-changed");
  }
};

LineItemCustomize.prototype.get_line_field = function(line_item, key){
  if(key == "earliest_start" || key == "ideal_start" || key == "finish_by" || key == "length")
    return $("."+key+"_input", line_item);
  else
    return $("."+key, line_item);
};

LineItemCustomize.prototype.get_current_values = function(line_item){
  var request = {};
  request.earliest_start = this.get_line_field(line_item, 'earliest_start').val();
  request.finish_by      = this.get_line_field(line_item, 'finish_by').val();
  request.ideal_start    = this.get_line_field(line_item, 'ideal_start').val();
  request.length         = this.get_line_field(line_item, 'length').val();
  request.description    = this.get_line_field(line_item, 'description').val();
  request.location       = this.get_line_field(line_item, 'location').val();
  request.offer          = this.get_line_field(line_item, 'offer').val();
  request.comment        = this.get_line_field(line_item, 'comment').val();

  return request;
};

LineItemCustomize.prototype.cancel_modifications = function(line_item){
  if(this.current_values){
    // restore values
    this.get_line_field(line_item, 'earliest_start').val(this.current_values.earliest_start);
    this.get_line_field(line_item, 'finish_by').val(this.current_values.finish_by);
    this.get_line_field(line_item, 'ideal_start').val(this.current_values.ideal_start);
    this.get_line_field(line_item, 'length').val(this.current_values.length);
    this.get_line_field(line_item, 'description').val(this.current_values.description);
    this.get_line_field(line_item, 'location').val(this.current_values.location);
    this.get_line_field(line_item, 'offer').val(this.current_values.offer);
    this.get_line_field(line_item, 'comment').val(this.current_values.comment);
  }
};
