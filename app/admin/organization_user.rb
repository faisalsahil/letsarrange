ActiveAdmin.register OrganizationUser do
  # setting up menu
  menu parent: 'Organizations'

  belongs_to :organization, optional: true

  # setting up params allowed for create/update
  permit_params :name, :visibility

  # setting up default sort
  config.sort_order = "organization_users.name_asc"

  # setting up actions enabled
  actions :all, except: [:new,:create]

  # setting up filters
  filter :name
  filter :organization, label: 'Organization'
  filter :user, label: 'User'
  filter :visibility
  filter :status, as: :select, collection: OrganizationUserState::HUMANIZED.invert.to_a

  # setting up 'index' view
  index do
    column('Org Name', sortable: 'organizations.name') { |organization_user| organization_user.organization.name }
    column('Org ID', sortable: 'organizations.uniqueid') { |organization_user| link_to(organization_user.organization.uniqueid, admin_organization_path(organization_user.organization)) }
    column("User's Display Name", sortable: 'organization_users.name') { |organization_user| link_to(organization_user.name, admin_organization_user_path(organization_user)) }
    column('User Name', sortable: 'users.name') { |organization_user| organization_user.user.name }
    column('User ID', sortable: 'users.uniqueid') { |organization_user| link_to(organization_user.user.uniqueid, admin_user_path(organization_user.user)) }
    column('Status', sortable: 'status', &:humanized_status)
    column :visibility

    default_actions
  end

  # setting up 'form' used to new/edit
  form do |f|
    f.inputs "Details" do
      f.input :name,
              label: "User's Display Name",
              input_html: { class: 'form-control' },
              required: false, placeholder: "e.g. Jamie Black"

      f.input :visibility,
              required: false,
              input_html: { class: 'form-control' },
              collection: [['Public', 'public'], ['Private', 'private']]

      f.input :status,
              required: false,
              input_html: { class: 'form-control' },
              as: :select,
              collection: OrganizationUserState::HUMANIZED.invert.to_a
    end

    f.actions
  end

  # setting up 'show' view
  show do
    render 'admin/organization_users/show'
  end

  controller do
    def scoped_collection
      end_of_association_chain.includes([:organization, :user])
    end
  end

end
