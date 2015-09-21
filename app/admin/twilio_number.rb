ActiveAdmin.register TwilioNumber do
  config.sort_order = "twilio_numbers.number_asc"

  actions :index, :show

  collection_action :reload_numbers do
    TwilioNumber.load_twilio_numbers
    redirect_to({ action: :index }, notice: 'Numbers reloaded successfully!')
  end

  action_item :only => :index do
    link_to('Reload numbers from Twilio', reload_numbers_admin_twilio_numbers_path)
  end

  filter :number

  index do
    column :number
    column('Reserved for') do |twilio_number|
      request = twilio_number.request
      request ? link_to(request.title, admin_request_path(request)) : '-'
    end
    column('With active mappings') { |twilio_number| twilio_number.phone_mappings.active.exists? ? 'Yes' : '-' }
    column(:status, sortable: :status, &:humanized_status)
    column('Actions') do |twilio_number|
      html = link_to('view', admin_twilio_number_path(twilio_number))
      html << " | ".html_safe
      html << link_to('phone mappings', admin_twilio_number_phone_mappings_path(twilio_number))
      html
    end
  end

  show do
    attributes_table do
      row :id
      row :number
      row(:status, &:humanized_status)
      row('Reserved for') { twilio_number.request ? link_to(twilio_number.request.title, admin_request_path(twilio_number.request)) : '-' }
      row('Active mappings?') { twilio_number.phone_mappings.active.exists? ? 'Yes' : '-' }
    end
    panel 'Actions' do
      text_node(link_to('View phone mappings', admin_twilio_number_phone_mappings_path(twilio_number)))
    end
  end

  controller do
    def scoped_collection
      end_of_association_chain
    end
  end
end
