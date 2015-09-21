ActiveAdmin.register UrlMapping do
  # setting up menu
  menu priority: 5, parent: 'Mappings'

  belongs_to :user, optional: true

  # setting up actions enabled
  actions :all, except: [:new,:create]

  # setting up filters
  filter :user
  filter :contact_point, label: 'Contact Method'
  filter :code
  filter :path, label: 'Full url'
  filter :status

  controller do
    # belongs_to :user
    # belongs_to :contact_point

    def index
      # params[:q] ||= { s: 'user_name ASC' }
      @search = UrlMapping.includes(contact_point: :user).where('contact_point_id IS NOT NULL').search(params[:q])

      search_query = if params[:contact_point_id].present?
                       @search.result.where(contact_point_id: params[:contact_point_id])
                     elsif params[:user_id].present?
                       @search.result.where(contact_points: { user_id: params[:user_id] })
                     else
                       @search.result
                     end

      # overriding ActiveAdmin sorting options, since we're overriding 'index' method
      order     = params[:order].blank? ? "users.name_asc" : params[:order]
      order     = order.gsub('_asc',' asc').gsub('_desc',' desc')

      @url_mappings = search_query.order(order).page(params[:page])
    end
  end

  # setting up 'index' view
  index do
    column :user, sortable: 'users.name'
    column('Contact Method', sortable: 'contact_points.description') { |um| link_to(um.contact_point.description, admin_user_contact_point_path(um.contact_point.user, um.contact_point)) }
    column :code
    column('Short url', sortable: 'code') { |um| link_to(um.to_short_url, "http://#{ um.to_short_url }") }
    column('Full url', sortable: :path) { |um| um.path }
    column('Status', sortable: :status, &:humanized_status)
    column('Actions') do |url_mapping|
      html = link_to('edit', edit_admin_url_mapping_path(url_mapping))
      html << " | ".html_safe
      html << destroy_row(:url_mapping, url_mapping)
      html
    end
  end

end
