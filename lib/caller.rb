class Caller
  attr_accessor :caller_id, :organization_resource, :organization_user

  def initialize(callback_number, organization_resource = nil, organization_user = nil)
    @caller_id = callback_number.number
    @organization_resource = organization_resource
    @organization_user = organization_user
  end

  def ==(other)
    caller_id == other.caller_id && organization_resource == other.organization_resource && organization_user == other.organization_user
  end
end