ActiveAdmin.register Resource do
  # setting up menu
  menu priority: 3

  # setting up params allowed for create/update
  permit_params :uniqueid, :name

  # setting up default sort
  config.sort_order = "uniqueid_asc"

  # setting up actions enabled
  actions :all, except: [:new,:create]

  # setting up filters
  filter :name
  filter :uniqueid, label: 'Resource ID'

  # setting up 'index' view
  index do
    column('Resource ID', sortable: :uniqueid) { |resource| link_to(resource.uniqueid, admin_resource_path(resource)) }
    column :name

    default_actions
  end

  # setting up 'form' used to new/edit
  form do |f|
    f.inputs "Details" do
      f.input :name,
              input_html: { class: 'form-control' },
              placeholder: "e.g. Dana White",
              required: false, autofocus: true
      f.input :uniqueid,
              input_html: { class: 'form-control' },
              label: "Resource ID",
              placeholder: "e.g. danawhite79",
              required: false, autofocus: true
    end

    f.actions
  end

  # setting up 'show' view
  show do
    render 'admin/resources/show'
  end

end
