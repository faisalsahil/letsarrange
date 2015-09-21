module Admin
  module LineItemHelper
    def self.link_for_number number
      user = User.find_user(sms: number).first
      return number if TwilioNumber.where(number: number).exists? || !user

      contact = user.contact_points.where(description: number).first
      ActionController::Base.helpers.link_to number,Rails.application.routes.url_helpers.admin_user_contact_point_path(user,contact)
    end

    def self.link_for_mail(address)
      domain = Mail::Address.new(address).domain
      return address if domain == ENV['MAIL_DOMAIN'] || domain == ENV['MAILNET_DOMAIN']
      user = User.find_user(email: address).first
      contact = user.contact_points.where(description: address).first
      ActionController::Base.helpers.link_to address,Rails.application.routes.url_helpers.admin_user_contact_point_path(user,contact)
    end

    def entity_link(entity)
      if entity.is_a?(LineItem)
        link_to("Line Item #{ entity.id }", admin_request_line_item_path(entity.request, entity))
      else
        link_to("Inbound Number #{ entity.id }", admin_inbound_number_path(entity))
      end
    end
  end
end