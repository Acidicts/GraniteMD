class Dashboard::OrganisationsController < DashboardController
  before_action :set_organisation, only: %i[ show edit update destroy ]

  def index
    @organisations = current_user.organisations.order(name: :desc)
    @organisation_applications = OrganisationApplication.where(owner_id: current_user.id).where.missing(:organisation).order(created_at: :desc)
  end

  def new
    @organisation = OrganisationApplication.new
  end

  def create
    @organisation = OrganisationApplication.new(organisation_application_params)
    @organisation.owner_id = current_user.id
    if @organisation.save
      redirect_to dashboard_organisation_path(@organisation), notice: "Application was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def show
    return unless @organisation

    @workspaces = @organisation.workspaces.order(name: :asc)
  end

  def update
  end

  def destroy
  end

  private

  def organisation_params
    params.require(:organisation).permit(:name)
  end

  def organisation_application_params
    params.require(:organisation_application).permit(:name, :pitch)
  end

  def set_organisation
    @organisation = Organisation.find_by(public_id: params[:public_id])
    redirect_to dashboard_organisations_path unless @organisation&.users&.include?(current_user)
  end
end
