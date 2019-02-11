class CreateDocuments < ActiveRecord::Migration[5.2]
  def change
    create_table :documents do |t|
      t.string :uuid
      t.string :extension
      t.string :metadata
      t.string :filename
      t.string :url
      t.string :mime_type
      t.integer :status

      t.timestamps
    end
  end
end
