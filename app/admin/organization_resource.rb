ActiveAdmin.register OrganizationResource do
  # setting up menu
  menu parent: 'Organizations'

  # setting up params allowed for create/update
  permit_params :name, :visibility

  # setting up default sort
  config.sort_order = "organization_resources.name_asc"

  # setting up actions enabled
  actions :all, except: [:new,:create]

  # setting up filters
  filter :name
  filter :organization, label: 'Organization'
  filter :resource, label: 'Resource'
  filter :visibility

  # setting up 'index' view
  index do
    column('Org Name', sortable: 'organizations.name') { |organization_resource| organization_resource.organization.name }
    column('Org ID', sortable: 'organizations.uniqueid') { |organization_resource| link_to(organization_resource.organization.uniqueid, admin_organization_path(organization_resource.organization)) }
    column("Resource's Display Name", sortable: 'organization_resources.name') { |organization_resource| link_to(organization_resource.name, admin_organization_resource_path(organization_resource)) }
    column('Resource Name', sortable: 'resources.name') { |organization_resource| organization_resource.resource.name }
    column('Resource ID', sortable: 'resources.uniqueid') { |organization_resource| link_to(organization_resource.resource.uniqueid, admin_resource_path(organization_resource.resource)) }
    column :visibility

    default_actions
  end

  # setting up 'form' used to new/edit
  form do |f|
    f.inputs "Details" do
      f.input :name,
              label: "Resource's Display Name",
              input_html: { class: 'form-control' },
              required: false, placeholder: "e.g. Jamie Black"

      f.input :visibility,
              required: false,
              input_html: { class: 'form-control' },
              collection: [['Public', 'public'], ['Private', 'private']]
    end

    f.actions
  end

  # setting up 'show' view
  show do
    render 'admin/organization_resources/show'
  end

  controller do
    def scoped_collection
      end_of_association_chain.includes([:organization, :resource])
    end
  end

end
