require "rails_helper"

# Regressions for the open redirect via a spoofed Host header.
#
# Two layers, because either alone is load-bearing:
#   1. config.hosts rejects an unknown Host at the edge (403), so there is no
#      spoofed request to exploit in the first place.
#   2. the stored return_to is a bare path, so even if a bad Host somehow got
#      through, redirect_to could not be pointed at another site.
RSpec.describe "Sign-in return_to", type: :request do
  let(:user) { create(:user, email_address: "u@example.com", username: "uuser") }

  def sign_in
    post login_path, params: { email_address: user.email_address, password: "Password1!" }
  end

  it "blocks a spoofed Host header before it reaches the application" do
    get workspaces_path, headers: { "HTTP_HOST" => "evil.example.com" }

    expect(response).to have_http_status(:forbidden)
  end

  it "blocks a spoofed Host header on the sign-in request too" do
    post login_path,
         params: { email_address: user.email_address, password: "Password1!" },
         headers: { "HTTP_HOST" => "evil.example.com" }

    expect(response).to have_http_status(:forbidden)
    expect(Session.count).to eq(0)
  end

  it "returns the user to the path they asked for" do
    get workspaces_path
    expect(response).to redirect_to(login_path)

    sign_in

    expect(response).to redirect_to(workspaces_path)
  end

  it "falls back to the dashboard when nothing was stored" do
    sign_in

    expect(response).to redirect_to(dashboard_path)
  end

  it "keeps the query string even when it looks like a hostile URL" do
    get "/workspaces?next=//evil.example.com"
    expect(response).to redirect_to(login_path)

    sign_in

    expect(response.location).to include("/workspaces?next=//evil.example.com")
    expect(response.location).not_to start_with("//")
  end

  it "consumes the stored path, so a second sign-in goes to the dashboard" do
    get workspaces_path
    sign_in
    expect(response).to redirect_to(workspaces_path)

    delete logout_path
    sign_in

    expect(response).to redirect_to(dashboard_path)
  end
end
