require "rails_helper"

RSpec.describe "Password resets", type: :request do
  # Reset instructions are queued rather than delivered inline, so the jobs
  # have to be run before the mail assertions can see anything.
  include ActiveJob::TestHelper

  let(:user) { create(:user) }

  def token_from_last_email
    html = ActionMailer::Base.deliveries.last.html_part.body.decoded
    html[%r{/passwords/([^/'"\s]+)/edit}, 1]
  end

  before do
    ActionMailer::Base.deliveries.clear
    clear_enqueued_jobs
  end

  describe "GET /passwords/new" do
    it "renders the request form" do
      get new_password_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /passwords" do
    it "emails a link that opens the reset form" do
      assert_enqueued_emails 1 do
        post passwords_path, params: { email_address: user.email_address }
      end
      perform_enqueued_jobs

      expect(response).to redirect_to(login_path)
      expect(ActionMailer::Base.deliveries.size).to eq(1)

      token = token_from_last_email
      expect(token).to be_present

      get edit_password_path(token)
      expect(response).to have_http_status(:success)
    end

    it "accepts an address that differs only by case or padding" do
      perform_enqueued_jobs do
        post passwords_path, params: { email_address: "  #{user.email_address.upcase}  " }
      end

      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end

    it "does not reveal whether the address is registered" do
      post passwords_path, params: { email_address: "nobody@example.com" }

      expect(response).to redirect_to(login_path)
      expect(flash[:notice]).to be_present
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  describe "GET /passwords/:token/edit" do
    it "renders the form for a live token" do
      get edit_password_path(user.generate_token_for(:password_reset))

      expect(response).to have_http_status(:success)
    end

    it "rejects a forged token" do
      get edit_password_path("not-a-real-token")

      expect(response).to redirect_to(new_password_path)
      expect(flash[:alert]).to be_present
    end

    it "rejects a token once the window has passed" do
      token = user.generate_token_for(:password_reset)

      travel_to User::PASSWORD_RESET_TOKEN_TTL.from_now + 1.minute do
        get edit_password_path(token)
      end

      expect(response).to redirect_to(new_password_path)
    end
  end

  describe "PUT /passwords/:token" do
    let(:token) { user.generate_token_for(:password_reset) }
    let(:valid) { { password: "Newpass1!", password_confirmation: "Newpass1!" } }

    it "sets the new password and ends every existing session" do
      user.sessions.create!(user_agent: "RSpec", ip_address: "127.0.0.1")

      put password_path(token), params: valid

      expect(response).to redirect_to(login_path)
      expect(user.reload.authenticate("Newpass1!")).to be_truthy
      expect(user.sessions).to be_empty
    end

    it "keeps the token from being replayed" do
      put password_path(token), params: valid

      put password_path(token), params: valid
      expect(response).to redirect_to(new_password_path)
    end

    it "re-renders the form when the confirmation does not match" do
      put password_path(token), params: { password: "Newpass1!", password_confirmation: "Different1!" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("alert alert-error")
      expect(user.reload.authenticate("Password1!")).to be_truthy
    end

    it "re-renders the form when the password fails the strength rules" do
      put password_path(token), params: { password: "weak", password_confirmation: "weak" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.authenticate("Password1!")).to be_truthy
    end

    it "rejects a forged token without touching the password" do
      put password_path("not-a-real-token"), params: valid

      expect(response).to redirect_to(new_password_path)
      expect(user.reload.authenticate("Password1!")).to be_truthy
    end

    it "rejects a token once the window has passed" do
      stale = token

      travel_to User::PASSWORD_RESET_TOKEN_TTL.from_now + 1.minute do
        put password_path(stale), params: valid
      end

      expect(response).to redirect_to(new_password_path)
      expect(user.reload.authenticate("Password1!")).to be_truthy
    end
  end
end
