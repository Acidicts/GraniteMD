class ApplicationController < ActionController::Base
  include Authentication

  allow_browser versions: :modern
  layout "application"

  helper_method :current_user

  before_action :current_url
  before_action :current_path

  def current_user
    return unless session[:user_id]
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def current_url
    @current_url = request.original_url
  end

  def current_path
    @current_path = request.path
  end
end
