class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "Try again later." }
  layout "home", only: %i[ new edit update ]

  def new
  end

  def edit
  end

  def create
    user = User.find_by(email_address: email_address_param)
    send_reset_instructions(user) if user

    redirect_to login_path, notice: "If an account exists for that address, we have sent password reset instructions."
  end

  def update
    if @user.update(password_params)
      @user.sessions.destroy_all
      redirect_to login_path, notice: "Password has been reset."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
  def email_address_param
    User.normalize_value_for(:email_address, params[:email_address].to_s)
  end

  def password_params
    params.permit(:password, :password_confirmation)
  end

  def set_user_by_token
    @user = User.find_by_token_for(:password_reset, params[:token])
    return if @user

    redirect_to new_password_path, alert: "Password reset link is invalid or has expired."
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_password_path, alert: "Password reset link is invalid or has expired."
  end

  def send_reset_instructions(user)
    helpers.send_email(
      user.email_address,
      "Password Reset",
      "A password reset was requested for your GraniteMD account. " \
      "<a href='#{edit_password_url(user.generate_token_for(:password_reset))}'>Choose a new password</a>. " \
      "This link expires #{User::PASSWORD_RESET_TOKEN_TTL.inspect} after it was sent. " \
      "If you did not request it, no changes have been made and you can ignore this email."
    )
  end
end
