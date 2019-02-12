class CreateDocuments < ActiveRecord::Migration[5.2]
  def change
    create_table :documents do |t|
      t.string :uuid
      t.string :format
      t.string :metadata
      t.string :filename

      t.timestamps
    end
  end
end
