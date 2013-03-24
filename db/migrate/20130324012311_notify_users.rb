class NotifyUsers < ActiveRecord::Migration
  def up
    execute "ALTER TABLE skins ADD column created_on timestamp not null default now();"
    execute "ALTER TABLE skins ADD column updated_on timestamp not null default now();"
    subject = "Skins borradas debido a migración a un nuevo sistema de skins"
    User.find(:all, :conditions => "id IN (SELECT distinct(user_id) from skins where skin_variables IS NULL)").each do |u|
      body = "Hola #{u.login}, lo siento corazón pero he tenido que eliminar tus skins debido a <a href=\"http://gamersmafia.com/foros/topic/41486\">cambios recientes en el sistema de skins</a> que las han hecho incompatibles. Si necesitas alguno de los archivos anteriores por favor ponte en contacto con <a href=\"/miembros/Draco351\">Draco351</a>. Si te animas a crear skins con el nuevo sistema puedes hacerlo <a href=\"http://gamersmafia.com/cuenta/skins\">desde esta sección</a>.<br /><br />Agradezco tu paciencia y siento los inconvenientes."
      m = Message.new(:title => subject, :sender => Ias.nagato, :recipient => u, :message => body)
      m.save
    end
    execute "DELETE FROM skins WHERE skin_variables IS NULL;"
  end

  def down
  end
end
