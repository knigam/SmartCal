class EventsController < ApplicationController
  before_action :set_event, only: [:show, :edit, :update, :destroy]

  # GET /events
  # GET /events.json
  def index
    @events = current_user.events
  end

  # GET /events/1
  # GET /events/1.json
  def show
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
    if not current_user.invites.find_by_event_id(@event.id).creator
      redirect_to @event, notice: 'You do not have permission to edit that event'
    end
  end

  # POST /events
  # POST /events.json
  def create
    @event = Event.create(event_params)

    respond_to do |format|
      if @event.save
        invite = current_user.invites.build(creator: true)
        invite.event = @event
        invite.save
        @event.place
        @event.conflict?

        format.html { redirect_to @event, notice: 'Event was successfully created.' }
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/1
  # PATCH/PUT /events/1.json
  def update
    if not current_user.invites.find_by_event_id(params[:id]).creator
      redirect_to @event, notice: 'You do not have permission to edit that event'
    end
    @event.assign_attributes(event_params)
    @event.place
    @event.conflict?
    respond_to do |format|
      if @event.save
        format.html { redirect_to @event, notice: 'Event was successfully updated.' }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1
  # DELETE /events/1.json
  def destroy
    if not current_user.invites.find_by_event_id(@event.id).creator
      redirect_to @event, notice: 'You do not have permission to delete that event'
    end
    @event.destroy
    respond_to do |format|
      format.html { redirect_to events_url, notice: 'Event was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = current_user.events.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def event_params
        params.require(:event).permit(:title, :description, :location, :start_time, :end_time, :start_bound, :end_bound, :duration, :color)
    end
end
