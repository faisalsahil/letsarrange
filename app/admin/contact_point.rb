ActiveAdmin.register ContactPoint do
  belongs_to :user

  # setting up params allowed for create/update
  permit_params :type, :description

  # setting up actions enabled
  actions :all, except: [:new,:create]

  # disabling filters
  config.filters = false

  # setting up 'index' view
  index do
    column(:description) { |cp| link_to cp, admin_user_contact_point_path(cp.user, cp) }
    column :type
    column('Status', sortable: 'status', &:humanized_status)
    column('Actions') { |cp| destroy_row(:user_contact_point, cp.user, cp) }
  end

  show do
    attributes_table do
      row :description
      row(:type, &:humanized_type)
      row(:status) { contact_point.humanized_status(for_admin: true) }
      row(:owned_by) { link_to contact_point.user.uniqueid, admin_user_path(contact_point.user) }
    end
    panel('Messages') { render 'admin/broadcasts/message_types_table', contact_point: contact_point, show_broadcast_link: true }
    panel('Actions') { text_node(link_to "View url mappings", admin_contact_point_url_mappings_path(contact_point)) }
  end

  # setting up 'form' used to new/edit
  form do |f|
    f.inputs "Details" do
      f.input :type,
              required: false,
              input_html: { class: 'form-control' },
              collection: [['Voice', 'ContactPoint::Voice'], ['Sms', 'ContactPoint::Sms'], ['Email', 'ContactPoint::Email']],
              autofocus: true
      f.input :description,
              required: false,
              input_html: { class: 'form-control' },
              autofocus: true
    end

    f.actions
  end

  # adding 'verify' member POST action
  member_action :verify, method: :post do
    @user = User.find(params[:user_id])
    @contact_point = @user.contact_points.find(params[:id])
    @contact_point.mark_as_verified!
    redirect_to admin_user_contact_point_url(@user,@contact_point)
  end

  controller do
    def destroy
      destroy! { admin_user_path(@user) }
    end
  end
end
