class CreateDocuments < ActiveRecord::Migration[5.2]
  def change
    create_table :documents do |t|
      t.string :uuid
      t.string :format
      t.string :metadata
      t.string :filename
      t.string :mime_type

      t.timestamps
    end
  end
end
