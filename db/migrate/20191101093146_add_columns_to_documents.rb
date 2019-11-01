class AddColumnsToDocuments < ActiveRecord::Migration[5.2]
  def change
    add_column :documents, :username, :string
    add_column :documents, :email, :string

    Hackney::Cloud::Document.find_each do |document|
      next if document.metedata.blank?

      metadata = JSON.parse(document.metedata)

      user = Hackney::Income::Models::User.find_by(id: metadata['user_id'])

      next if user.blank?

      document.update!(username: user.name, email: user.email)
    end
  end
end
