class CreateTypesEvents < ActiveRecord::Migration
  def change
    create_table :events_types, id: false do |t|
      t.references :event
      t.references :type
    end

    add_index :events_types, [:event_id, :type_id]
    add_index :events_types, :type_id
  end
end
