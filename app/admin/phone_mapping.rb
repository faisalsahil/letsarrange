ActiveAdmin.register PhoneMapping do
  # setting up menu
  menu priority: 2, parent: 'Mappings'

  belongs_to :user, optional: true

  # setting up actions enabled
  actions :all, except: [:new,:create]

  # setting up filters
  filter :user
  filter 'twilio_number_number'
  filter :code
  filter :status

  # setting up 'index' view
  index do
    column :user, sortable: 'users.name'
    column(:twilio_number, sortable: 'twilio_numbers.number')
    column :code
    column('Entity') { |phone_mapping| entity_link(phone_mapping.entity) }
    column('Status', sortable: :status, &:humanized_status)
    column('Actions') do |phone_mapping|
      html = link_to('edit', edit_admin_phone_mapping_path(phone_mapping))
      html << " | ".html_safe
      html << destroy_row(:phone_mapping, phone_mapping)
      html
    end
  end

  controller do
    def scoped_collection
      if params[:user_id].present?
        end_of_association_chain.includes(:twilio_number, :user).where(user_id: params[:user_id])
      elsif params[:twilio_number_id].present?
        end_of_association_chain.includes(:twilio_number, :user).where(endpoint_id: params[:twilio_number_id])
      else
        end_of_association_chain.includes(:twilio_number, :user)
      end
    end
  end
end
