require 'test_helper'

module StatusableState
  STATUS1 = 0
  STATUS2 = 1

  TRANSITIONS = {
      STATUS1 => [STATUS2],
      STATUS2 => []
  }

  HUMANIZED = {
      STATUS1 => 'status 1',
      STATUS2 => 'status 2'
  }
end

class Statusable
  extend StatusProvider

  attr_accessor :status
  add_status_with StatusableState

  def destroy; end
  def run_callbacks(*args); yield; end
  def self.default_scope; end
  def self.scope(*args); end
end

class StatusProviderTest < ActiveSupport::TestCase
  def setup
    super
    line_item_with_assoc!
    @statusable = @line_item
  end

  test 'status_provider should return the module used as status enum' do
    statusable = Statusable.new
    assert_equal StatusableState, statusable.status_provider
    assert_equal StatusableState, statusable.class.status_provider
  end

  test 'humanized status should return the user friendly label of its status' do
    statusable = Statusable.new
    statusable.status = StatusableState::STATUS1
    assert_equal 'status 1', statusable.humanized_status
    statusable.status = StatusableState::STATUS2
    assert_equal 'status 2', statusable.humanized_status
  end

  test 'change_status should fetch the status upcasing the symbol given' do
    statusable = Statusable.new
    statusable.status = StatusableState::STATUS1
    statusable.status_provider.expects(:const_get).with(:SOMESTATUS)
    statusable.send(:change_status, :somestatus)
  end

  test 'change_status should change the status if the transition is valid' do
    statusable = Statusable.new
    statusable.status = StatusableState::STATUS1
    statusable.expects(:update).with(status: StatusableState::STATUS2)
    statusable.send(:change_status, :status2)
  end

  test 'change_status should not change the status if the transition is valid' do
    statusable = Statusable.new
    statusable.status = StatusableState::STATUS2
    statusable.expects(:update).never
    statusable.send(:change_status, :status1)
  end

  test 'if soft_delete is passed with truthy value, it should, by default, exclude deleted records when fetching' do
    @statusable.status = LineItemState::DELETED
    @statusable.save(validate: false)
    assert_equal 0, LineItem.count
    assert_equal 1, LineItem.unscoped.count
  end

  test 'if soft_delete is passed with truthy value, destroy should not delete the record' do
    @statusable.save(validate: false)
    @statusable.destroy
    assert @statusable.persisted?
  end

  test 'if soft_delete is passed with truthy value, destroy should set the status to deleted' do
    @statusable.save(validate: false)
    @statusable.destroy
    assert_equal LineItemState::DELETED, @statusable.status
  end

  test 'if soft_delete is passed with a truthy value, destroy should change the status to deleted' do
    Statusable.send(:add_status_with, StatusableState, soft_delete: true)
    statusable = Statusable.new
    statusable.expects(:change_status).with(:deleted)
    statusable.destroy
  end

  test 'if soft_delete is missing or passed with a falsy value, destroy should destroy the record for good' do
    statusable = Statusable.new
    statusable.expects(:destroy_with_flag).never
    statusable.destroy
  end
end