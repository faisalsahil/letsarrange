class AddRequestIdToInboundNumbers < ActiveRecord::Migration
  def up
    add_column :inbound_numbers, :request_id, :integer

    InboundNumber.find_each do |inbound|
      if inbound.twilio_number_id
        request = Request.find_by(reserved_number_id: inbound.twilio_number_id)
        if request
          inbound.request_id = request.id
        else
          inbound.destroy
        end
      end
    end

    remove_column :inbound_numbers, :twilio_number_id
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
