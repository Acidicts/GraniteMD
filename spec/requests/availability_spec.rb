require "rails_helper"

RSpec.describe "Availability checks", type: :request do
  let!(:taken) { create(:user, email_address: "taken@example.com", username: "takenuser") }

  # Forgery protection is off in the test environment, so switch it on to
  # exercise the same CSRF requirement the browser is subject to.
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  # Mirrors how the Stimulus controller obtains the token.
  def csrf_token
    get new_password_path
    response.body[/<meta name="csrf-token" content="([^"]+)"/, 1]
            .to_s.gsub("&#39;", "'").gsub("&quot;", '"')
  end

  def check(path, params, token:)
    post path, params: params.to_json,
                headers: { "Content-Type" => "application/json", "X-CSRF-Token" => token }
  end

  it "refuses GET so the lookup cannot be fired cross-origin" do
    get "/unique_email", params: { email_address: taken.email_address }

    expect(response).to have_http_status(:not_found)
  end

  it "rejects a POST without a valid CSRF token" do
    check "/unique_email", { email_address: taken.email_address }, token: "not-the-token"

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "reports a taken email as unavailable" do
    check "/unique_email", { email_address: taken.email_address }, token: csrf_token

    expect(response).to have_http_status(:success)
    expect(response.parsed_body).to eq("available" => false)
  end

  it "reports an unknown email as available" do
    check "/unique_email", { email_address: "nobody@example.com" }, token: csrf_token

    expect(response.parsed_body).to eq("available" => true)
  end

  it "matches usernames case- and whitespace-insensitively" do
    check "/unique_username", { username: "  TAKENUSER  " }, token: csrf_token

    expect(response.parsed_body).to eq("available" => false)
  end

  it "reports a blank username as unavailable" do
    check "/unique_username", { username: "   " }, token: csrf_token

    expect(response.parsed_body).to eq("available" => false)
  end
end
