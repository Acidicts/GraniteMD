class BackfillOrganisationPublicId < ActiveRecord::Migration[8.1]
  class Organisation < ActiveRecord::Base
    self.table_name = "organisations"
  end

  def up
    Organisation.reset_column_information

    Organisation.where(public_id: [ nil, "" ]).find_each do |organisation|
      public_id = loop do
        candidate = SecureRandom.alphanumeric(8).downcase
        break candidate unless Organisation.where("LOWER(public_id) = ?", candidate).exists?
      end

      organisation.update_column(:public_id, public_id)
    end
  end

  def down
    # No-op: keep assigned public ids.
  end
end
