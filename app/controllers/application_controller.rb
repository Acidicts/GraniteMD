class ApplicationController < ActionController::Base
  include Authentication

  allow_browser versions: :modern
  layout "application"
end
