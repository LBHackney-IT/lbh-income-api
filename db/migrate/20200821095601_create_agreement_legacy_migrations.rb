class CreateAgreementLegacyMigrations < ActiveRecord::Migration[5.2]
  def change
    create_table :agreement_legacy_migrations do |t|
      t.bigint :legacy_id

      t.timestamps
    end

    add_belongs_to :agreement_legacy_migrations, :agreement, foreign_key: true
  end
end
