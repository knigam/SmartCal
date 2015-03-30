class Friendship < ActiveRecord::Base
    belongs_to :user
    belongs_to :friend, :class_name => 'User'
    validates_uniqueness_of :user_id, :scope => "friend_id"
    validate :friend_is_not_self

    def friend_is_not_self
        errors.add(:friend_id, "can't add self as friend") if user_id == friend_id
    end
end
