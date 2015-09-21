module LandingHelper
  def show_login?
    request.url.include?("page=2") or params['action'] == 'create'
  end
end