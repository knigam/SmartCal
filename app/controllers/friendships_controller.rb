class FriendshipsController < ApplicationController
    def create
        if params[:friend_id]
            user = User.find(params[:friend_id])
        elsif params[:email]
            user = User.find_by_email(params[:email])
        end
        if user
            @friendship = current_user.friendships.build(:friend_id => user.id)
            if @friendship.save
                flash[:notice] = "Added friend."
            else
                flash[:notice] = "Unable to add friend."
            end
        end
        redirect_to friendships_path
    end

    def destroy
        @friendship = current_user.friendships.find_by_friend_id(params[:id])
        @friendship.destroy
        respond_to do |format|
          format.html { redirect_to friendships_url, notice: 'Friend was successfully deleted.' }
          format.json { head :no_content }
        end
    end

    def search
        @friends = User.where("email LIKE?", "%#{params[:email]}%")
    end
end
