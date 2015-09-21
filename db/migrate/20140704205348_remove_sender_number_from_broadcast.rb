class RemoveSenderNumberFromBroadcast < ActiveRecord::Migration
  def change
    Broadcast.where(broadcastable_type: Request).find_each do |b|
      request = Request.find_by(id: b.broadcastable_id)
      if b[:sender_number] && request && request.reserved_number.present?
        b.broadcastable = InboundNumber.find_or_create_by!(number: b[:sender_number], twilio_number: request.reserved_number)
        b.save!(validate: false)
      end
    end
    remove_column :broadcasts, :sender_number
  end
end
