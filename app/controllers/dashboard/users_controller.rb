module Dashboard
  class UsersController < DashboardController
    allow_unauthenticated_access only: %i[ new create ]
    before_action :set_user, only: %i[ edit update ]

    layout "home", only: %i[ new ]

    def index
    end

    def edit
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
      if @user.update(user_params)
        redirect_to dashboard_users_path, notice: "Profile was successfully updated.", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    private
    def set_user
      @user = params[:id] ? User.find(params.expect(:id)) : current_user
    end

    def user_params
      params.require(:user).permit(:first_name, :last_name, :username, :email_address)
    end

    def signup_params
      params.require(:user).permit(:first_name, :last_name, :username, :email_address, :password, :password_confirmation)
    end
  end
end
