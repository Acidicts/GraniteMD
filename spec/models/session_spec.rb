require "rails_helper"

# == Schema Information
#
# Table name: sessions
#
#  id           :bigint           not null, primary key
#  ip_address   :string
#  last_seen_at :datetime         not null
#  token        :string           not null
#  user_agent   :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_sessions_on_token    (token) UNIQUE
#  index_sessions_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
RSpec.describe Session, type: :model do
  let(:user) { create(:user) }

  def create_session
    user.sessions.create!(user_agent: "RSpec", ip_address: "127.0.0.1")
  end

  describe "#idle_expired?" do
    let(:last_seen) { Time.utc(2026, 1, 1, 12, 0, 0) }
    let(:session) { create_session.tap { |record| record.update_column(:last_seen_at, last_seen) } }

    it "is live while the account is still being used" do
      travel_to last_seen + Session::IDLE_TIMEOUT - 1.second do
        expect(session).not_to be_idle_expired
      end
    end

    it "is expired at exactly 30 minutes of inactivity" do
      travel_to last_seen + Session::IDLE_TIMEOUT do
        expect(session).to be_idle_expired
      end
    end

    it "is expired once 30 minutes pass without activity" do
      travel_to last_seen + Session::IDLE_TIMEOUT + 1.minute do
        expect(session).to be_idle_expired
      end
    end
  end

  describe "#register_activity" do
    it "slides the idle window forward" do
      session = create_session

      travel_to Session::IDLE_TIMEOUT.from_now - 1.minute do
        session.register_activity
      end

      travel_to Session::IDLE_TIMEOUT.from_now do
        expect(session).not_to be_idle_expired
      end
    end

    it "skips the write when called again straight away" do
      session = create_session

      expect(session.register_activity).to be(false)
    end

    it "writes again once the interval has passed" do
      session = create_session

      travel_to Session::ACTIVITY_WRITE_INTERVAL.from_now + 1.second do
        expect(session.register_activity).to be(true)
      end
    end
  end

  describe "activity stamping" do
    it "stamps last_seen_at on create" do
      expect(create_session.last_seen_at).to be_within(5.seconds).of(Time.current)
    end
  end

  describe "scopes" do
    it "separates idle sessions from active ones" do
      idle = create_session
      idle.update_column(:last_seen_at, 1.hour.ago)
      active = create_session

      expect(Session.idle_active).to contain_exactly(active)
      expect(Session.idle_expired).to contain_exactly(idle)
    end
  end
end
