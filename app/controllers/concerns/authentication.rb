module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
  def authenticated?
    resume_session
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session ||= find_session_by_cookie
    slide_session
    Current.session
  end

  def find_session_by_cookie
    token = cookies.signed[:session_token]
    return if token.blank?

    found = Session.find_by_token(token)
    return if found.blank?
    return found unless found.idle_expired?

    found.destroy
    cookies.delete(:session_token)
    nil
  end

  def request_authentication
    session[:return_to_after_authenticating] = internal_path(request.fullpath)
    redirect_to login_path
  end

  # Only ever hand back a path on this host. Storing the full request URL would
  # let a spoofed Host header decide where the user lands after signing in, and
  # Rails' own open-redirect guard cannot catch that because the host would
  # simply match the request.
  def after_authentication_url
    internal_path(session.delete(:return_to_after_authenticating)) || dashboard_path
  end

  def internal_path(candidate)
    path = candidate.to_s.delete("\r\n")
    path if path.start_with?("/") && !path.start_with?("//", "/\\")
  end

  def start_new_session_for(user)
    Session.sweep_expired!
    user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |created|
      Current.session = created
      write_session_cookie(created)
    end
  end

  # Keeps the cookie's lifetime in step with the idle window so the browser
  # stops presenting a token the server would reject anyway.
  def slide_session
    return unless Current.session&.register_activity

    write_session_cookie(Current.session)
  end

  def write_session_cookie(record)
    cookies.signed[:session_token] = {
      value: record.token,
      expires: Session::IDLE_TIMEOUT.from_now,
      httponly: true,
      same_site: :lax,
      secure: request.ssl?
    }
  end

  def terminate_session
    Current.session.destroy
    cookies.delete(:session_token)
  end
end
