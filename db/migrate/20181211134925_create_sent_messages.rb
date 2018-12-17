class CreateSentMessages < ActiveRecord::Migration[5.1]
  def change
    create_table :sent_messages do |t|
      t.string :tenancy_ref
      t.string :template_id
      t.string :version
      t.string :message_type
      t.text :personalisation
      t.timestamps
    end
  end
end
