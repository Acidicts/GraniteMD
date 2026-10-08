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

  it "blocks a different user from editing another user's profile" do
    attacker = create(:user, email_address: "attacker@example.com", username: "attacker")
    other = create(:user, email_address: "other@example.com", username: "otheruser")
    cookies.delete(:session_token)
    sign_in attacker

    patch dashboard_user_path(other), params: { user: { first_name: "Hacked" } }

    expect(response).to redirect_to(dashboard_path)
    expect(other.reload.first_name).not_to eq("Hacked")
  end

  it "rejects uploads over 2MB" do
    fake_file = rack_test_file("x" * (2.megabytes + 100), "image/png")
    patch dashboard_user_path(user), params: { user: { pfp_image: fake_file } }, as: :multipart

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("must be less than 2MB")
    expect(user.reload.pfp_image.attached?).to be false
  end

  it "rejects non-image file types" do
    fake_file = rack_test_file("<?xml version=\"1.0\"?><html>", "application/octet-stream")
    patch dashboard_user_path(user), params: { user: { pfp_image: fake_file } }, as: :multipart

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("must be an image")
    expect(user.reload.pfp_image.attached?).to be false
  end

  def rack_test_file(content, content_type)
    Rack::Test::UploadedFile.new(StringIO.new(content), content_type, original_filename: "test.png")
  end
end
