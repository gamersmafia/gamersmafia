class AddIconToGameAndPlatforms < ActiveRecord::Migration
  def up
    execute "alter table games add column icon varchar;"
    execute "alter table gaming_platforms add column icon varchar;"
    execute "update games set icon = 'storage/games/' || slug || '.gif';"
    execute "update gaming_platforms set icon = 'storage/games/' || slug || '.gif';"
  end
end
