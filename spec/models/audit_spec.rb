require 'rails_helper'

# == Schema Information
#
# Table name: audits
#
#  id             :bigint           not null, primary key
#  action         :string           not null
#  auditable_type :string
#  details        :json
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  auditable_id   :bigint
#  user_id        :bigint
#
# Indexes
#
#  index_audits_on_action     (action)
#  index_audits_on_auditable  (auditable_type,auditable_id)
#  index_audits_on_user_id    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
RSpec.describe Audit, type: :model do
  describe "factory" do
    it "is valid with factory attributes" do
      expect(build(:audit)).to be_valid
    end
  end

  describe "validations" do
    it "requires an action" do
      audit = build(:audit, action: nil)

      expect(audit).not_to be_valid
      expect(audit.errors[:action]).to be_present
    end
  end

  describe "associations" do
    it "belongs to a user" do
      association = Audit.reflect_on_association(:user)

      expect(association.macro).to eq(:belongs_to)
    end

    it "allows a nil user" do
      audit = build(:audit, user: nil)

      expect(audit).to be_valid
    end

    it "belongs to an auditable polymorphically" do
      association = Audit.reflect_on_association(:auditable)

      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:polymorphic]).to be(true)
    end

    it "allows a nil auditable" do
      audit = build(:audit, auditable: nil)

      expect(audit).to be_valid
    end

    it "can be associated with an auditable record" do
      user = create(:user)
      audit = create(:audit, auditable: user)

      expect(audit.auditable).to eq(user)
      expect(audit.auditable_type).to eq("User")
      expect(audit.auditable_id).to eq(user.id)
    end
  end
end
