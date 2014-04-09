class RenameChangelogsDatetimeToChangetime < ActiveRecord::Migration
  def change
    rename_column :changelogs, :datetime, :changetime
  end
end
