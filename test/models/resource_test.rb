require 'test_helper'

class ResourceTest < ActiveSupport::TestCase
  should have_many :organization_resources
  should have_many(:organizations).through(:organization_resources)

  should validate_presence_of :name
  should validate_presence_of :uniqueid
  should validate_uniqueness_of :uniqueid

  test 'should set uniqueid if not present' do
    @resource = Resource.create(name: 'Homer', visibility: 'public')
    assert @resource.uniqueid.present?
  end

end