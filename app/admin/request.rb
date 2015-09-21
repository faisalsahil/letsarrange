ActiveAdmin.register Request do
  # setting up menu
  menu priority: 4

  belongs_to :organization, optional: true

  # setting up actions enabled
  actions :all, except: [:new,:create]

  # setting up filters
  filter :organization, label: 'Org ID'
  filter :organization_resource, label: 'Org Resource'
  filter :description
  filter :location

  controller do
    # belongs_to :organization
    # belongs_to :user

    def index
      @search = Request.includes([:organization, :organization_resource]).search(params[:q])

      search = if params[:organization_id].present? || params[:user_id].present?
                 organization_ids = params[:organization_id] || OrganizationUser.where(user_id: params[:user_id]).map(&:organization_id)
                 organization_resources = OrganizationResource.where(organization_id: organization_ids)
                 @search.result.where(organization_resource_id: organization_resources).references(:organization)
               else
                 @search.result
               end

      # overriding ActiveAdmin sorting options, since we're overriding 'index' method
      order     = params[:order].blank? ? "organizations.uniqueid_asc" : params[:order]
      order     = order.gsub('_asc',' asc').gsub('_desc',' desc')
      @requests = search.order(order).page(params[:page])
    end
  end

  # setting 'index' view
  index do
    column('Org. ID', sortable: 'organizations.uniqueid') { |request| link_to(request.organization.uniqueid, admin_organization_path(request.organization)) }
    column('Org. resource', sortable: 'organization_resources.name') { |request| link_to(request.organization_resource.name, admin_organization_resource_path(request.organization_resource)) }
    column :description
    column :location
    column('Start by', sortable: :earliest_start) { |request| request.earliest_start ? Admin::DateTimeHelper.format(request.earliest_start_in_tmz, request.time_zone) : '-' }
    column('Finish by', sortable: :finish_by) { |request| request.finish_by ? Admin::DateTimeHelper.format(request.finish_by_in_tmz, request.time_zone) : '-' }
    column :time_zone
    column :length
    column :offer
    column('Requestor', sortable: :created_by) { |request| link_to(request.created_by.full_name, admin_organization_user_path(request.created_by)) }
    column('Status', sortable: :status, &:humanized_status)
    column('Reserved number') { |request| link_to(request.reserved_number, admin_twilio_number_path(request.reserved_number)) if request.reserved_number }
    column('Actions') do |request|
      html = link_to('view', admin_request_path(request))
      html << " | ".html_safe
      html << link_to('inbound numbers', admin_request_inbound_numbers_path(request))
      html << " | ".html_safe
      html << destroy_row(:request, request)
      html
    end
  end

  show title: 'Request' do
    render 'admin/requests/show'
  end

end
