class AddNotesToAgreementsTable < ActiveRecord::Migration[5.2]
  def change
    add_column :agreements, :notes, :text
  end
end
