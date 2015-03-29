class CreateInvites < ActiveRecord::Migration
  def change
    create_table :invites do |t|
      t.integer :event_id, index: true
      t.integer :user_id, index: true
      t.boolean :creator, default: false
      t.boolean :attending
      t.timestamps null: false
    end
  end
end
