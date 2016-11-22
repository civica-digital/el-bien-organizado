class ProjectsController < ApplicationController
  include ProjectsHelper

  before_action :set_project, only: [:show, :edit, :update, :destroy]

  def index
    if params[:organization_id]
      @projectable = Organization.find(params[:organization_id])
    elsif params[:investor_id]
      @projectable = Investor.find(params[:investor_id])
    end
  end

  def show
    authorize @project
    @collaborators = @project.collaborators.map { |id| Organization.find(id) }
    render :layout => "profiles"
  end

  def new
    @organization = Organization.find(params[:organization_id])
    @project = @organization.projects.new
    @collaborator = Organization.all
    authorize @project
  end

  def edit
    authorize @project
    @organization = Organization.find(params[:organization_id])
    @collaborator = Organization.all
  end

  def create
    @project = Project.new(project_params)
    @project.projectable = current_user.profile # TO-DO: Refactor this
    authorize @project

    supports = project_params[:collaborators].keep_if { |x| not x.empty? }
 
    respond_to do |format|
      if @project.save
        collaborators = Organization.where('id in (?)', supports).each do |collaborator|
          collaborator.supports.push @project.id
          collaborator.save
        end

        format.html { redirect_to polymorphic_path([@project.projectable, @project] ), notice: I18n.t('project.notices.successfully_created') }
        format.json { render :show, status: :created, location: @project }
      else
        format.html { render :new }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @project

    supports = project_params[:collaborators].keep_if { |x| not x.empty? }

    collaborators = Organization.where('id in (?)', supports).each do |collaborator|
      collaborator.supports.push @project.id unless collaborator.supports.include? @project.id
      collaborator.save
    end
    
    diff = @project.collaborators - supports
    collaborators += Organization.where('id in (?)', diff).each do |collaborator|
      collaborator.supports.delete @project.id unless  collaborator.supports.include? @project.id
      collaborator.save
    end


    respond_to do |format|
      if @project.update(project_params) and collaborators.flatten.any?
        format.html { redirect_to polymorphic_path([@project.projectable, @project] ), notice: I18n.t('project.notices.successfully_created') }
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  def list
    skip_authorization
    if params[:q]
      projects = Project.multisearch(params[:q])
      causes = retrive_projects_with CAUSE.search(params[:q]).ids

      @projects = causes.push(*projects).uniq
    else
      @projects = Project.all
    end
  end

  def causes
    skip_authorization
  end

  private
    def set_project
      @project = Project.find(params[:id])
    end

   def project_params
    params.require(:project).permit(:name, :goals, :description, :status, :photo_project,:town,
                                     :direction, :comments_from_direction, :name_of_owner,
                                     :email, :phone, :website, :twitter, :facebook, :organization_id,
                                     :lat, :lng, :other_causes, causes_interest: [], clasification: [], collaborators: [])
   end
end
