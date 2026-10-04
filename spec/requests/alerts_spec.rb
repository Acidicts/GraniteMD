require "rails_helper"

RSpec.describe "Alerts", type: :request do
  describe "flash rendering" do
    it "renders a granite-MD error alert for failed sign in" do
      post login_path, params: { email_address: "nobody@example.com", password: "wrong" }
      follow_redirect!

      expect(response.body).to include('class="alert alert-error"')
      expect(response.body).to include('role="alert"')
      expect(response.body).to include("Try another email address or password.")
      expect(response.body).to include('aria-label="Dismiss"')
      expect(response.body).to include("components/alerts")
      expect(response.body).to match(/class="flash-rail"/)
    end

    it "renders a granite-MD info alert for notices" do
      user = create(:user)
      sign_in user

      patch dashboard_user_path(user), params: { user: { first_name: "Updated" } }
      follow_redirect!

      expect(response.body).to include('class="alert alert-info"')
      expect(response.body).to include('role="status"')
      expect(response.body).to include("Profile was successfully updated.")
    end

    it "renders a warn alert set with alert(warn:) from a controller" do
      user = create(:user)
      other = create(:user, email_address: "other@example.com", username: "otheruser")
      sign_in user

      get edit_dashboard_user_path(other)
      follow_redirect!

      expect(response.body).to include('class="alert alert-warn"')
      expect(response.body).to include('role="status"')
      expect(response.body).to include("You do not have access to this user")
    end
  end
end
