class UrlMapping < ActiveRecord::Base
  include TokenGenerator
  include StateScopes

  CODE_LENGTH = 8

  belongs_to :contact_point
  has_one :user, through: :contact_point

  validates :path, uniqueness: { scope: :contact_point_id }

  before_create :generate_code

  scope :with_path, ->(*args) { where(path: send(*args)) } # with_path(some_named_url, some_required_param, some_optional_param: value)

  add_status_with MappingState

  def to_short_url
    to_url(ENV['URL_MAPPING_HOST'])
  end

  def to_url(host = ENV['HOST_URL'])
    UrlMapping.url_mapping_url(code: code, host: host).sub('http://', '')
  end

  def attach_to(body, separator: ' ')
    tail = "#{ separator }#{ to_short_url }"
    #attach only if attaching wont make the body to be split in an extra sms chunk
    last_chunk_length = body.length % SmsMessage::MAX_LENGTH
    if last_chunk_length.nonzero? && last_chunk_length + tail.length <= SmsMessage::MAX_LENGTH
      "#{ body }#{ tail }"
    else
      body
    end
  end

  private

  def generate_code
    generate_token(:code, length: CODE_LENGTH)
  end

  class << self
    include ActionView::Helpers
    include Rails.application.routes.url_helpers

    def create_for(contact_point, mappeable = nil)
      to_path = mappeable ? mappeable.mapping_path : contact_points_path
      contact_point.url_mappings.active.where(path: to_path).first_or_create!
    end

    def fetch_mapping!(code)
    active.find_by(code: code) or fail NoRouteFoundException.new
    end

    def static_mapping(path_name, *args)
      path = send(:"#{ path_name }_path", *args)
      UrlMapping.active.where(path: path).first_or_create!
    end
  end
end