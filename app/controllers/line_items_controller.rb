class LineItemsController < ApplicationController
  respond_to :html, :js
  with_options only: :show do |f|
    f.skip_before_filter :authenticate_user!
    f.before_filter :sign_in_by_url_mapping
  end

  def show
    @request = Request.find(params.require(:request_id))
    @line_item = @request.line_items.find(params.require(:id))
    fail AccessDeniedError unless current_user.can_view_line_item?(@line_item)
    @reply = @line_item.broadcasts.build    
    @line_item.line_change = LineChange.new

    request_attributes = @request.attributes.slice("earliest_start", "finish_by", "ideal_start", "length", "description", "location", "offer")
    
    request_attributes.each do |key,value|
      request_attributes[key] = "" unless value
    end

    js resources: @line_item.requested_organization.resources.map { |r| {name: r.name} },
        request_tmz: @line_item.time_zone,
        request: request_attributes
    
    respond_with @line_item
  end

  def received
    @line_items = current_user.received_line_items.including_associations.order(:earliest_start)
    respond_with @line_items
  end

  def update
    case params[:commit]
    when 'Close' then close
    when 'Decline' then close
    else
      fields_update
    end
  rescue ActiveRecord::RecordInvalid, AccessDeniedError => invalid
    @error_message = invalid.message
    render "error"
  end

  private

  def close
    @line_item = fetch_line_item
    @line_item.close(broadcast_sender: current_user, closing_message: params[:line_item][:line_change][:comment].presence)
  end

  def fields_update
    line = fetch_line_item
    fail AccessDeniedError unless current_user.can_view_line_item?(line)
    @line_item = LineItemDispatcher.new(line, current_user).dispatch(params[:line_item])
  end

  def fetch_line_item
    params.require(:line_item).permit!
    @request = Request.find params.require(:request_id)
    @request.line_items.find params.require(:id)
  end
end