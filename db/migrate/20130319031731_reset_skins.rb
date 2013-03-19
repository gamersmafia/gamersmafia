class ResetSkins < ActiveRecord::Migration
  def up
    subject = "Skin reseteada"
    UsersPreference.find(:all, :conditions => 'name = \'skin\'', :include => :user).each do |uf|
      body = "Hola #{uf.user.login}, lo siento de corazón pero he tenido que resetearte la skin que tenías configurada a la skin por defecto debido a <a href=\"http://gamersmafia.com/foros/topic/41486\">cambios recientes en el sistema de skins</a>. Si te animas a crear una skin puedes hacerlo <a href=\"http://gamersmafia.com/cuenta/skins\">desde esta sección</a>.<br /><br />Agradezco tu paciencia y siento los inconvenientes."
      m = Message.new(:title => subject, :sender => Ias.nagato, :recipient => uf.user, :message => body)
      m.save
      uf.destroy
    end
    execute "delete from users_preferences where name = 'skin_id';"
    execute "alter table users_preferences add column created_on timestamp not null default now();"
    execute "alter table users_preferences add column updated_on timestamp not null default now();"
  end

  def down
  end
end
