ActiveAdmin.register User do
  # setting up menu
  menu priority: 1

  # setting up params allowed for create/update
  permit_params :uniqueid, :name, :password

  # setting up default sort
  config.sort_order = "uniqueid_asc"

  # setting up actions enabled
  actions :all, except: [:new,:create]

  # setting up filters
  filter :name
  filter :uniqueid, label: 'User ID'

  # setting up 'index' view
  index do
    column('User ID', sortable: :uniqueid) { |user| link_to user.uniqueid, admin_user_path(user) }
    column :name
    column 'Is Admin', :admin
    column('Default Org Resource', sortable: :uniqueid) { |user| user.default_org_resource ? user.default_org_resource.full_name : '' }
    column('Last Login', sortable: :last_sign_in_at) { |user| user_last_login_info(user) }

    default_actions
  end

  # setting up 'form' used to new/edit
  form do |f|
    f.inputs "Details" do
      f.input :name,
              input_html: { class: 'form-control' },
              required: false, placeholder: "e.g. Jamie Black"

      f.input :uniqueid,
              input_html: { class: 'form-control' },
              label: "User ID",
              placeholder: "e.g. jamieblack72",
              required: false, autofocus: true

      f.input :password,
              autocomplete: "off",
              input_html: { class: 'form-control' },
              placeholder: "at least 8 characters",
              required: false
    end

    f.actions
  end

  # setting up 'show' view
  show do
    render 'admin/users/show'
  end

  # adding 'set_admin' member action
  member_action :set_admin, method: :patch do
    @user = User.find(params[:id])
    @user.update(admin: params[:enable].present?)
    redirect_to admin_user_path(@user)
  end

  controller do
    # Letting users to be updated without password set, but still keeping the posibility to update user's password
    def update_resource(object, attributes)
      update_method = attributes.first[:password].present? ? :update_attributes : :update_without_password
      object.send(update_method, *attributes)
    end
  end

end
