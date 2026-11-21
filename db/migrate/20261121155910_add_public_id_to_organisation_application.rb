class AddPublicIdToOrganisationApplication < ActiveRecord::Migration[8.1]
  class OrganisationApplication < ActiveRecord::Base
    self.table_name = "organisation_applications"
  end

  def up
    add_column :organisation_applications, :public_id, :string

    OrganisationApplication.reset_column_information
    OrganisationApplication.where(public_id: [ nil, "" ]).find_each do |application|
      public_id = loop do
        candidate = SecureRandom.alphanumeric(8).downcase
        break candidate unless OrganisationApplication.where("LOWER(public_id) = ?", candidate).exists?
      end

      application.update_column(:public_id, public_id)
    end

    add_index :organisation_applications, :public_id, unique: true
  end

  def down
    remove_index :organisation_applications, :public_id
    remove_column :organisation_applications, :public_id
  end
end
