class FriendshipsController < ApplicationController
    def create
        @friendship = current_user.friendships.build(:friend_id => params[:friend_id])

        if @friendship.save
            flash[:notice] = "Added friend."
            redirect_to friendships_path
        else
            flash[:notice] = "Unable to add friend."
            redirect_to friendships_path
        end
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
