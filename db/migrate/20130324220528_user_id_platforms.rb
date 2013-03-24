class UserIdPlatforms < ActiveRecord::Migration
  def up
    execute "alter table gaming_platforms add column user_id int references users match full;"
    execute "update gaming_platforms set user_id = (SELECT id FROM users where lower(login) = 'mrman')"
    execute "alter table gaming_platforms add column created_on timestamp not null default now();"
    execute "alter table gaming_platforms add column updated_on timestamp not null default now();"
  end

  def down
  end
end
