class ChangeOfferPriceToOffer < ActiveRecord::Migration
  def change
    %i(requests line_items).each do |table|
      add_column table, :offer, :string
    end
  end
end