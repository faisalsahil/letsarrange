class UsersController < ApplicationController
  respond_to :html, :json

  def index
    clean_id = params[:q].present? ? User.clean(params[:q]) : ''
    users    = User.public.by_uniqueid(clean_id)
    users.concat(User.public.typeahead_order.where('uniqueid LIKE ?', "%#{ clean_id }%"))
    if org = Organization.find_by_id(params[:org_id])
      users = users - org.users
    end

    render json: users, only: [:uniqueid, :name]
  end

  def show
    @user = User.find(params[:id])
  end

  private

  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_url) unless current_user?(@user)
  end
end