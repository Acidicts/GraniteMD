module AuthenticationHelpers
  def sign_in(user, password: user.password)
    post login_path, params: { email_address: user.email_address, password: password }
    expect(response).to redirect_to(dashboard_url), "login failed for #{user.email_address}"
  end
end
