class UrlMappingsController < ApplicationController
  respond_to :html
  skip_before_filter :authenticate_user!

  def show
    code = params.permit(:code)[:code]
    mapping = UrlMapping.fetch_mapping!(code)
    redirect_to path_to_url(mapping.path, code: code)
  rescue NoRouteFoundException
    redirect_to new_user_session_url(host: ENV['HOST_URL'], alert: 'Unknown code')
  end

  private

  def path_to_url(path, url_params)
    url = "https://#{ ENV['HOST_URL'] }/#{ path.sub(%r[^/],'') }"
    if url_params
      url << (path['?'] ? '&' : '?') << url_params.to_param
    end
  end
end