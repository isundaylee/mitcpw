class AddCpwIdToEvents < ActiveRecord::Migration
  def change
    add_column :events, :cpw_id, :integer
  end
end
