class AddPitchToOrganisationApplication < ActiveRecord::Migration[8.1]
  def change
    add_column :organisation_applications, :pitch, :text
  end
end
