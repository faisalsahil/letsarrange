ActiveAdmin.register InboundNumber do
  actions :all, except: [:new,:create]

  filter :request

  index do
    column :id
    column :number
    column('Request') do |inbound|
      request = inbound.request
      request ? link_to(request.title, admin_request_path(request)) : '-'
    end
    default_actions
  end

  show do
    default_main_content
    panel('Broadcasts') { render('admin/broadcasts/table', broadcasts: inbound_number.broadcasts) }
  end

  controller do
    def scoped_collection
      if params[:request_id].present?
        end_of_association_chain.includes(:request).where(request_id: params[:request_id])
      else
        end_of_association_chain.includes(:request)
      end
    end
  end
end
