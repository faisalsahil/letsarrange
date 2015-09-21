class InboundNumbersController < ApplicationController
  def merge
    inbound = InboundNumber.find(params[:inbound_number_id])
    if @merged_broadcasts = inbound.merge_into(params.require(:broadcast)[:broadcastable_id])
      @target_line_item = @merged_broadcasts.first.broadcastable
      flash.now[:success] = @merged_broadcasts.length == 1 ? 'The broadcast was successfully transferred' : 'The broadcasts were successfully transferred'
    else
      flash.now[:error] = 'An error occurred'
      render_flash_only
    end
  end
end