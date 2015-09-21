require 'test_helper'

class VisibilityScopesTest < ActiveSupport::TestCase
  def setup
    super
    @public = Organization.create!(name: 'o1', uniqueid: 'o1', visibility: 'public')
    @private = Organization.create!(name: 'o2', uniqueid: 'o2', visibility: 'private')
  end

  test 'private should include records with visibility private' do
    assert_equal [@private], Organization.private.to_a
  end

  test 'public should include records with visibility public' do
    assert_equal [@public], Organization.public.to_a
  end
end