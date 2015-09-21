ActiveAdmin.register LineItem do
  menu false

  # setting up actions enabled
  actions :all, except: [:new,:create]

  # disabling filters
  config.filters = false

  controller do
    belongs_to :request, :resource, :organization_resource, polymorphic: true

    def index
      org_resources_id = if params[:organization_resource_id].present?
                           params[:organization_resource_id]
                         elsif params[:resource_id].present?
                           OrganizationResource.where(resource_id: params[:resource_id])
                         end
      # @search = LineItem.includes(:resource, organization_resource: :requested_organization).where(organization_resource_id: org_resources_id).search(params[:q])
      @search = LineItem.includes(:resource, :requested_organization).where(organization_resource_id: org_resources_id).search(params[:q])

      # overriding ActiveAdmin sorting options, since we're overriding 'index' method
      order     = params[:order].blank? ? "organizations.uniqueid_asc" : params[:order]
      order     = order.gsub('_asc',' asc').gsub('_desc',' desc')

      @line_items = @search.result.order(order).page(params[:page])
    end

    def destroy
      destroy! do
        @request.persisted? ? admin_request_path(@request) : admin_requests_path
      end
    end
  end

  # setting 'index' view
  index title: 'Line Items' do
    column('Org. ID', sortable: 'organizations.uniqueid') { |line_item| link_to(line_item.requested_organization.uniqueid, admin_organization_path(line_item.requested_organization)) }
    column('Resource ID', sortable: 'resources.uniqueid') { |line_item| link_to(line_item.resource.uniqueid, admin_resource_path(line_item.resource)) }
    column :description
    column :location
    column('Start by', sortable: :earliest_start) { |line_item| line_item.earliest_start ? Admin::DateTimeHelper.format(line_item.earliest_start_in_tmz, line_item.time_zone) : '-' }
    column('Finish by', sortable: :finish_by) { |line_item| line_item.finish_by ? Admin::DateTimeHelper.format(line_item.finish_by_in_tmz, line_item.time_zone) : '-' }
    column :length
    column :offer
    column('Status', sortable: :status, &:humanized_status)
    column('Actions') do |line_item|
      html = link_to("view", admin_request_line_item_path(line_item.request,line_item))
      html << " | ".html_safe
      html << link_to("request", admin_request_path(line_item.request))
      html << " | ".html_safe
      html << destroy_row(:request_line_item, line_item.request, line_item)
      html
    end
  end

  show do
    render 'admin/line_items/show'
  end
end
