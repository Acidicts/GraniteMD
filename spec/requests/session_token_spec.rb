require "rails_helper"

RSpec.describe "Session tokens", type: :request do
  let(:user) { create(:user, email_address: "u@example.com", username: "uuser") }

  def session_cookie
    Array(response.headers["Set-Cookie"]).find { |value| value.start_with?("session_token=") }
  end

  # Signed cookies are a readable base64 envelope with an HMAC suffix; the
  # message inside is base64-encoded JSON.
  def decoded_cookie(name)
    raw = Array(response.headers["Set-Cookie"]).find { |value| value.start_with?("#{name}=") }
    payload = raw.to_s.split(";").first.to_s.split("=", 2).last.to_s.split("--").first.to_s
    JSON.parse(Base64.decode64(CGI.unescape(payload)).tr("\u0000", ""))
  rescue ArgumentError, JSON::ParserError
    {}
  end

  it "puts an opaque token in the cookie, not the primary key" do
    sign_in user
    record = Session.sole

    expect(record.token).to be_present
    expect(session_cookie).to be_present
    # Rails base64-encodes, then JSON-encodes, the value inside the metadata.
    message = decoded_cookie("session_token").dig("_rails", "message")
    expect(JSON.parse(Base64.decode64(message))).to eq(record.token)
  end

  it "issues a different token for every session" do
    first = user.sessions.create!(user_agent: "RSpec", ip_address: "127.0.0.1")
    second = user.sessions.create!(user_agent: "RSpec", ip_address: "127.0.0.1")

    expect(first.token).not_to eq(second.token)
    expect(first.token.length).to be >= 24
  end

  it "does not leak the row id inside the signed cookie payload" do
    sign_in user
    record = Session.sole

    # Compare the decoded value against the id rather than substring-matching the
    # raw payload: the envelope holds a base64 blob and an ISO8601 expiry, both of
    # which contain digits for every small id.
    message = decoded_cookie("session_token").dig("_rails", "message")
    carried = JSON.parse(Base64.decode64(message))

    expect(carried).to eq(record.token)
    expect(carried).not_to eq(record.id.to_s)
    expect(carried.length).to be >= 24
  end

  it "never resolves a session from the row id alone" do
    sign_in user
    record = Session.sole

    # The token is the only lookup key: knowing an id must not be enough.
    expect(Session.find_by_token(record.id.to_s)).to be_nil
    expect(Session.find_by_token(nil)).to be_nil
  end

  it "resumes the session from the token alone" do
    sign_in user
    get dashboard_path
    expect(response).to have_http_status(:success)
  end

  it "ignores a blank or unknown token" do
    expect(Session.find_by_token(nil)).to be_nil
    expect(Session.find_by_token("")).to be_nil
    expect(Session.find_by_token("nope")).to be_nil
  end
end

RSpec.describe Session, ".purge_expired!" do
  let(:user) { create(:user, email_address: "p@example.com", username: "puser") }

  it "deletes idle-expired rows and keeps live ones" do
    stale = user.sessions.create!(user_agent: "RSpec", ip_address: "127.0.0.1")
    live = user.sessions.create!(user_agent: "RSpec", ip_address: "127.0.0.1")
    stale.update_column(:last_seen_at, Session::IDLE_TIMEOUT.ago - 1.minute)

    expect(Session.purge_expired!).to eq(1)
    expect(Session.exists?(stale.id)).to be false
    expect(Session.exists?(live.id)).to be true
  end

  it "classifies a freshly created session as active" do
    user.sessions.create!(user_agent: "RSpec", ip_address: "127.0.0.1")

    expect(Session.idle_active.count).to eq(Session.count)
    expect(Session.idle_expired.count).to eq(0)
  end

  it "is exposed as a rake task" do
    expect(Rails.root.join("lib/tasks/sessions.rake")).to exist
  end
end
