ActiveAdmin.register Organization do
  # setting up menu
  menu priority: 2

  # setting up params allowed for create/update
  permit_params :uniqueid, :name, :visibility

  belongs_to :user, optional: true

  # setting up default sort
  config.sort_order = "name_asc"

  # setting up actions enabled
  actions :all, except: [:new,:create]

  # setting up filters
  filter :uniqueid, label: 'Org ID'
  filter :name
  filter :visibility

  # setting up 'index' view
  index do
    column('Org ID', sortable: :uniqueid) { |organization| link_to(organization.uniqueid, admin_organization_path(organization)) }
    column('Org Name', sortable: :name) { |organization| organization.name }
    column :visibility

    default_actions
  end

  # setting up 'form' used to new/edit
  form do |f|
    f.inputs "Details" do
      f.input :name,
              label: "Org Name",
              input_html: { class: 'form-control' },
              placeholder: "e.g. Zen Spa",
              required: false, autofocus: true
      f.input :uniqueid,
              input_html: { class: 'form-control' },
              label: "Org ID",
              placeholder: "e.g. zenspa1234",
              required: false, autofocus: true
      f.input :visibility,
              required: false,
              input_html: { class: 'form-control' },
              collection: [['Public', 'public'], ['Private', 'private']]
    end

    f.actions
  end

  # setting up 'show' view
  show do
    render 'admin/organizations/show'
  end

  member_action :visibility, method: :patch do
    organization = Organization.find(params[:id])
    organization.update(visibility: params[:private] == '1' ? 'private' : 'public')
    redirect_to action: :show, success: 'The organization was successfully updated'
  end
end
