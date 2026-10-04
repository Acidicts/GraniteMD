module Dashboard
  class UsersController < DashboardController
    allow_unauthenticated_access only: %i[ new create unique_username unique_email ]
    before_action :set_user, only: %i[ edit update ]
    rate_limit to: 10, within: 3.minutes, only: %i[unique_username unique_email], with: -> { redirect_to login_path, alert: "Try again later." }

    layout "home", only: %i[ new ]

    def index
      @user = current_user
    end

    def edit
      if params[:id].present? && current_user.id.to_i != params[:id].to_i && !current_user.admin?
        alert(warn: "You do not have access to this user")
        return redirect_to dashboard_path
      end

      render partial: "dashboard/users/edit"
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(signup_params)

      if @user.save
        start_new_session_for @user
        redirect_to after_authentication_url, notice: "Your account was created.", status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if params[:id].present? && current_user.id.to_i != params[:id].to_i && !current_user.admin?
        alert(warn: "You do not have access to this user")
        return redirect_to dashboard_path
      end

      if @user.update(user_params)
        redirect_to dashboard_users_path, notice: "Profile was successfully updated.", status: :see_other
      else
        render partial: "dashboard/users/edit", status: :unprocessable_content
      end
    end

    def unique_username
      username = params[:username].to_s
      render json: { available: username.strip.present? && !User.exists?(username: username) }
    end

    def unique_email
      email = params[:email_address].to_s
      render json: { available: email.strip.present? && !User.exists?(email_address: email) }
    end

    private
    def set_user
      @user = params[:id] ? User.find(params.expect(:id)) : current_user
    end

    def user_params
      params.require(:user).permit(:first_name, :last_name, :username, :email_address, :pfp_image)
    end

    def signup_params
      params.require(:user).permit(:first_name, :last_name, :username, :email_address, :password, :password_confirmation)
    end
  end
end
