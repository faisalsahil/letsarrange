class TwilioNumber < ActiveRecord::Base
  has_one :request, -> { Request.open }, foreign_key: :reserved_number_id
  has_many :phone_mappings, foreign_key: :endpoint_id, dependent: :destroy

  # validates :number, presence: true, uniqueness: true

  scope :available, -> { not_reserved.not_mapped }

  before_destroy :close_request

  add_status_with TwilioNumberState

  def area_code
    ContactPoint::Phone.area_code(number)
  end

  def to_s
    ContactPoint::Phone.denormalized(number)
  end

  def reserved?
    !!request
  end

  def caller_id_for_number(number)
    caller_cp = VoiceSender.number_to_contact(number) || ContactPoint::Voice.new(number: number)
    mapping = if VoiceSender.anonymous_number?(number)
                request.first_line_item.author_mapping
              else
                request.receiver_for_reserved_message(caller_cp).author_mapping
              end
    mapping.twilio_number.number
  end

  private

  def close_request
    request.try(:close_dependencies)
    true
  end

  class << self
    def available_number(preferred_area_code)
      available_numbers = available.to_a
      available_numbers.find { |n| n.area_code == preferred_area_code } or
      available_numbers.first or
      buy_and_store_number(preferred_area_code)
    end

    def number_for_user(user, entity)
      existing_mapping = PhoneMapping.mapping_for(user, entity)
      if existing_mapping
        existing_mapping.twilio_number
      else
        less_used_number(user) or buy_and_store_number(user.preferred_area_code)
      end
    end

    def less_used_number(user)
      number = not_reserved.select("COUNT(CASE mappings.user_id WHEN '#{ user.id }' THEN 1 ELSE NULL END) AS usages, twilio_numbers.number").joins('LEFT JOIN mappings ON mappings.endpoint_id = twilio_numbers.id').where('mappings.id IS NULL OR (mappings.type = ? AND mappings.status = ?)', PhoneMapping, MappingState::ACTIVE).group('twilio_numbers.number').order('usages').first
      find_by(number: number.number) if number
    end

    def default_number
      not_reserved.first or buy_and_store_number
    end

    def load_twilio_numbers
      existing_numbers = TwilioNumber.pluck(:id)
      TwilioApi.incoming_numbers.each do |number|
        existing = find_or_initialize_by(number: number)
        existing.persisted? ? existing_numbers -= [existing.id] : existing.save!
      end
      where(id: existing_numbers).find_each(&:destroy)
    end

    def buy_and_store_number(area_code = nil)
      phone_number = TwilioApi.buy_number(area_code)
      create!(number: phone_number.delete('+'))
    end

    def not_reserved
      where.not(arel_table[:id].in(reserved_ids))
    end

    def not_mapped
      where.not(arel_table[:id].in(mapped_ids))
    end

    private

    def reserved_ids
      Request.open.with_reserved_number.uniq.pluck(:reserved_number_id)
    end

    def mapped_ids
      PhoneMapping.active.uniq.pluck(:endpoint_id)
    end
  end
end