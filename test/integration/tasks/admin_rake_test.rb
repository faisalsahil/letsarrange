require 'test_helper'
require 'rake'

class AdminRakeTest < ActiveSupport::TestCase
  def setup
    super
    Rake.application.rake_require "tasks/admin"
    Rake::Task.define_task(:environment)
    Object.any_instance.stubs(:puts)
  end

  test 'admin:grant should grant admin rights to the user with the given uniqueid' do
    u1 = create_user(uniqueid: 'user1')
    u2 = create_user(uniqueid: 'user2')
    assert !u1.admin?
    assert !u2.admin?
    Rake.application.invoke_task 'admin:grant[user1]'
    u1.reload
    u2.reload
    assert u1.admin?
    assert !u2.admin?
  end

  test 'admin:revoke should revoke admin rights of the user with the given uniqueid' do
    u1 = create_user(uniqueid: 'user1', admin: true)
    u2 = create_user(uniqueid: 'user2', admin: true)
    assert u1.admin?
    assert u2.admin?
    Rake.application.invoke_task 'admin:revoke[user1]'
    u1.reload
    u2.reload
    assert !u1.admin?
    assert u2.admin?
  end
end