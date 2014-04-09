class AddMessageToChangelogs < ActiveRecord::Migration
  def change
    add_column :changelogs, :message, :string
  end
end
