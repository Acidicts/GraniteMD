require "rails_helper"

RSpec.describe "Session expiry", type: :request do
  let(:user) { create(:user) }

  describe "idle window" do
    it "stays signed in while requests keep arriving" do
      sign_in user
      clock = Time.current

      # Far longer than the idle timeout in total, but never idle for 30 minutes.
      8.times do
        clock += Session::IDLE_TIMEOUT - 5.minutes

        travel_to clock do
          get dashboard_path
          expect(response).to have_http_status(:success)
        end
      end
    end

    it "signs out once 30 minutes pass with no requests" do
      sign_in user

      travel_to Session::IDLE_TIMEOUT.from_now + 1.minute do
        get dashboard_path
        expect(response).to redirect_to(login_path)
      end
    end

    it "stays signed in just inside the window" do
      sign_in user

      travel_to Session::IDLE_TIMEOUT.from_now - 1.minute do
        get dashboard_path
        expect(response).to have_http_status(:success)
      end
    end

    it "sends the user back where they were after signing in again" do
      sign_in user

      travel_to Session::IDLE_TIMEOUT.from_now + 1.minute do
        get workspaces_path
        expect(response).to redirect_to(login_path)

        post login_path, params: { email_address: user.email_address, password: user.password }
      end

      expect(response).to redirect_to(workspaces_url)
    end

    it "allows signing in again after the window closes" do
      sign_in user

      travel_to Session::IDLE_TIMEOUT.from_now + 1.minute do
        get dashboard_path
        expect(response).to redirect_to(login_path)
      end

      post login_path, params: { email_address: user.email_address, password: user.password }
      expect(response).to redirect_to(dashboard_url)
    end
  end

  describe "server-side enforcement" do
    it "rejects and reaps a session whose record is older than the window" do
      sign_in user
      user.sessions.update_all(last_seen_at: 1.hour.ago)

      get dashboard_path

      expect(response).to redirect_to(login_path)
      expect(Session.count).to eq(0)
    end

    it "keeps the session when the cookie outlives the record" do
      sign_in user
      user.sessions.update_all(last_seen_at: Time.current)

      get dashboard_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "cookie" do
    it "expires 30 minutes out on sign in rather than being permanent" do
      post login_path, params: { email_address: user.email_address, password: user.password }

      cookie = session_cookie
      expect(cookie).to be_present
      expect(Time.httpdate(cookie[/expires=([^;]+)/, 1])).to be_within(1.minute).of(Session::IDLE_TIMEOUT.from_now)
    end

    it "slides forward again once the write interval has passed" do
      sign_in user
      first = Time.httpdate(session_cookie[/expires=([^;]+)/, 1])

      travel_to Session::ACTIVITY_WRITE_INTERVAL.from_now + 1.minute do
        get dashboard_path
        expect(response).to have_http_status(:success)
      end

      expect(Time.httpdate(session_cookie[/expires=([^;]+)/, 1])).to be > first
    end

    it "is not re-issued on back-to-back requests" do
      sign_in user

      get dashboard_path
      first = response.headers["Set-Cookie"]
      get dashboard_path
      second = response.headers["Set-Cookie"]

      expect(Array(first).grep(/session_token=/)).to be_empty
      expect(Array(second).grep(/session_token=/)).to be_empty
    end

    it "leaves the record alone while requests arrive inside the interval" do
      sign_in user
      stamped = Session.sole.last_seen_at

      3.times { get dashboard_path }

      expect(Session.sole.last_seen_at).to eq(stamped)
    end
  end

  def session_cookie
    Array(response.headers["Set-Cookie"]).find { |value| value.start_with?("session_token=") }
  end
end
