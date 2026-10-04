require 'rails_helper'

RSpec.describe "Homes", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /faq" do
    it "returns http success" do
      get "/faq"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /about" do
    it "returns http success" do
      get "/about"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /team" do
    it "returns http success" do
      get "/team"
      expect(response).to have_http_status(:success)
    end
  end
end
