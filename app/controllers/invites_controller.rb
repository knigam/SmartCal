class InvitesController < ApplicationController
  def create
    @event = current_user.events.find(params[:event_id])
    user = User.find_by_email(params[:email])

    if user && Invite.create(event_id: @event.id, user_id: user.id, creator: false)
        @event.place
        @event.conflict?
        flash[:notice] = "Added user to event."
      else
        flash[:notice] = "Unable to add user to event."
    end
    redirect_to event_path(@event)
  end

  def destroy
    @invite = Invite.find(params[:id])
    if current_user.invites.find_by_event_id(@invite.event_id).creator
        event = @invite.event
        @invite.destroy
        event.place
        event.conflict?
      respond_to do |format|
        format.html { redirect_to event_path(@invite.event), notice: 'User successfully removed from event.' }
        format.json { head :no_content }
      end
    else
        respond_to do |format|
          format.html { redirect_to event_path(@invite.event), notice: 'Unable to remove user from event' }
          format.json { head :no_content }
        end
    end
  end
end
