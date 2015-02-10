class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :title
      t.text :description
      t.text :location
      t.datetime :start_time
      t.datetime :end_time
      t.time :duration
      t.datetime :start_bound
      t.datetime :end_bound
      t.integer :user_id

      t.timestamps
    end
  end
end
