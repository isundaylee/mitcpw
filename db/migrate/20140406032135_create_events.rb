class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :title
      t.datetime :from
      t.datetime :to
      t.string :location
      t.text :summary

      t.timestamps
    end
  end
end
