class RecipientsController < ApplicationController
  skip_before_filter :authenticate_user!, only: :create
  respond_to :json

  def create
    @recipients = RecipientsDispatcher.dispatch(params[:recipient])
    render json: @recipients
  end
end