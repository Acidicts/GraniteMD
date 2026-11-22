class Dashboard::OrganisationsController < DashboardController
  before_action :set_organisation, only: %i[ show edit update destroy ]
  before_action :set_organisation_application, only: %i[ appeal ]

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

  def appeal
    application = @organisation_application

    new_pitch = params[:new_pitch].to_s.strip
    if new_pitch.blank?
      return redirect_to dashboard_organisations_path, alert: "Your appeal pitch is empty, please provide appeal pitch"
    end

    submitted = application.with_lock do
      status_before = application.status
      pitch_before = application.pitch

      if application.appeal_locked? || !application.rejected?
        false
      else
        application.update!(status: :pending, pitch: new_pitch)

        application.audits.create!(
          user: current_user,
          action: "organisation application appeal created",
          details: {
            pitch_before: pitch_before,
            pitch_after: application.pitch,
            status_before: status_before,
            status_after: application.status
          }
        )
        true
      end
    end

    if submitted
      redirect_to dashboard_organisations_path, notice: "Appeal submitted."
    else
      redirect_to dashboard_organisations_path, alert: "Your organisation application is unable to be appealed"
    end
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
    @organisation = Organisation.find_by(public_id: params[:organisation_public_id] || params[:public_id])
    redirect_to dashboard_organisations_path unless @organisation&.users&.include?(current_user)
  end

  def set_organisation_application
    @organisation_application = OrganisationApplication.find_by(id: params[:id]) if params[:id].present?
    @organisation_application ||= OrganisationApplication.find_by(public_id: params[:public_id]) if params[:public_id].present?

    redirect_to dashboard_organisations_path unless @organisation_application&.owner == current_user
  end
end
