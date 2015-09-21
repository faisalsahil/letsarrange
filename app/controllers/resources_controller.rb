class ResourcesController < ApplicationController
  respond_to :json

  def index
    clean_id  = params[:q].present? ? Resource.clean(params[:q]) : ''
    resources = Resource.public.by_uniqueid(clean_id)
    resources.concat(Resource.public.typeahead_order.where('uniqueid LIKE ?', "%#{ clean_id }%"))
    if org = Organization.find_by_id(params[:org_id])
      resources = resources - org.resources
    end

    render json: resources, only: [:uniqueid, :name]
  end

end
