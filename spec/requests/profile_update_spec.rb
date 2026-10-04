require "rails_helper"

RSpec.describe "Profile updates", type: :request do
  let(:user) { create(:user, email_address: "me@example.com", username: "meuser") }

  before { sign_in user }

  it "re-renders the form with errors when the email is taken" do
    create(:user, email_address: "taken@example.com", username: "takenuser")

    patch dashboard_user_path(user), params: { user: { email_address: "taken@example.com" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Email in Use")
  end

  it "re-renders the form with errors when the username is taken" do
    create(:user, email_address: "taken@example.com", username: "takenuser")

    patch dashboard_user_path(user), params: { user: { username: "takenuser" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Username in Use")
  end

  it "still saves when the input is valid" do
    patch dashboard_user_path(user), params: { user: { first_name: "Updated" } }

    expect(response).to redirect_to(dashboard_users_path)
    expect(user.reload.first_name).to eq("Updated")
  end
end
