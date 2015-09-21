module InModalDetector
  extend ActiveSupport::Concern

  included do
    before_filter :set_in_modal, only: :create
  end

  private

  def set_in_modal
    @in_modal = params[:user].delete(:in_modal).present?
  end
end