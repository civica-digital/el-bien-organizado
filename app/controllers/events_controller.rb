class EventsController < ApplicationController
  before_action :event_params, only: :create
  before_action :authenticate_user!, except: [:show, :index]
  before_action :set_event, only: [:show, :edit, :update, :destroy]
 
 def show
  authorize @event
  end

  def new
    @organization = Organization.find(params[:organization_id])
    @event = @organization.events.new
    authorize @event
   
  end
  def edit
    authorize @event
    @organization = Organization.find(params[:organization_id])
  end

  def create
    @event = Event.new(event_params)
    @event.organization = current_user.profile # TO-DO: Refactor this
    authorize @event

    respond_to do |format|
      if @event.save
        format.html { redirect_to organization_events_path(@event.organization), notice: I18n.t('event.notices.successfully_created') }
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @event

    respond_to do |format|
      if @event.update(event_params)
        format.html { redirect_to organization_events_path(@event.organization), notice: I18n.t('event.notices.successfully_updated') }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end
  def index
    @organization = Organization.find(params[:organization_id])
  end

  def list
    skip_authorization
    if params[:q]
      @events = Event.multisearch(params[:q])
    else
      @events = Event.all
    end
  end


  private
    def set_event
      @event = Event.find(params[:id])
    end

   def event_params
    params.require(:event).permit(:name, :description, :notes, :image,:price, :date,:organization_id,:lat,:time, :lng,:address,:info,causes: [])
  end
end