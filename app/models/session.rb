# == Schema Information
#
# Table name: sessions
#
#  id           :bigint           not null, primary key
#  ip_address   :string
#  last_seen_at :datetime         not null
#  user_agent   :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_sessions_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Session < ApplicationRecord
  IDLE_TIMEOUT = 30.minutes

  # Activity is written at most this often, so a burst of requests costs one
  # UPDATE per interval rather than one per request. It is also the slop on the
  # idle check: a session can therefore idle for at most IDLE_TIMEOUT + this.
  ACTIVITY_WRITE_INTERVAL = 1.minute

  # Share of new sign-ins that also sweep expired rows. Abandoned sessions are
  # otherwise only reaped when their owner happens to come back with the cookie,
  # so without a scheduled `sessions:purge_expired` the table grows forever.
  PURGE_SWEEP_PROBABILITY = 0.05

  belongs_to :user

  # The cookie carries this token, never the primary key: row ids are
  # sequential and therefore guessable.
  has_secure_token :token

  scope :idle_expired, -> { where(last_seen_at: ..IDLE_TIMEOUT.ago) }
  scope :idle_active, -> { where.not(last_seen_at: ..IDLE_TIMEOUT.ago) }

  before_create :stamp_activity

  def self.find_by_token(token)
    return if token.blank?

    find_by(token: token)
  end

  def self.purge_expired!
    idle_expired.delete_all
  end

  def self.sweep_expired!
    purge_expired! if rand < PURGE_SWEEP_PROBABILITY
  end

  def idle_expired?
    last_seen_at <= IDLE_TIMEOUT.ago
  end

  # Slides the idle window forward. Returns true when a write actually happened,
  # which is the signal to re-issue the session cookie.
  def register_activity
    return false if recently_stamped?

    update_column(:last_seen_at, Time.current)
    true
  end

  private
  def recently_stamped?
    last_seen_at.present? && last_seen_at > ACTIVITY_WRITE_INTERVAL.ago
  end

  def stamp_activity
    self.last_seen_at ||= Time.current
  end
end
