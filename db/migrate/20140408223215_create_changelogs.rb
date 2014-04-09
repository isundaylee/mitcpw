class CreateChangelogs < ActiveRecord::Migration
  def change
    create_table :changelogs do |t|
      t.datetime :datetime
      t.integer :cpw_id

      t.timestamps
    end
  end
end
