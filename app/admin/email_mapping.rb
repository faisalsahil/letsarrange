ActiveAdmin.register EmailMapping do
  # setting up menu
  menu priority: 1, parent: 'Mappings'

  belongs_to :user, optional: true

  # setting up actions enabled
  actions :all, except: [:new,:create]

  # setting up filters
  filter :user
  filter :code
  filter :status

  # setting up 'index' view
  index do
    column :user, sortable: 'users.name'
    column :code
    column('Entity') { |email_mapping| entity_link(email_mapping.entity) }
    column('Status', sortable: :status, &:humanized_status)
    column('Actions') do |email_mapping|
      html = link_to('edit', edit_admin_email_mapping_path(email_mapping))
      html << " | ".html_safe
      html << destroy_row(:email_mapping, email_mapping)
      html
    end
  end

  controller do
    def scoped_collection
      if params[:user_id].present?
        end_of_association_chain.includes(:user).where(user_id: params[:user_id])
      else
        end_of_association_chain.includes(:user)
      end
    end
  end

end
