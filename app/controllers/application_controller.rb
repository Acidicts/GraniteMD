class ApplicationController < ActionController::Base
  include Authentication

  allow_browser versions: :modern
  layout "application"

  helper_method :current_user

  before_action :current_url
  before_action :current_path

  def current_user
    @current_user ||= resume_session&.user
  end

  def current_url
    @current_url = request.original_url
  end

  def current_path
    @current_path = request.path
  end

  private

  def alert(error: nil, warn: nil, info: nil, title: nil)
    type, message =
      if error.present?
        [ :error, error ]
      elsif warn.present?
        [ :warn, warn ]
      elsif info.present?
        [ :info, info ]
      end

    return super() if message.blank?

    flash[:alert_box] = { type: type, title: title.presence, message: message }
  end
end
