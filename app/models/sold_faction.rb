# -*- encoding : utf-8 -*-
class SoldFaction < SoldProduct
  def _use(options)
    @instance = load_faction_refered_instance(options)
    @instance.create_faction
    remove_old_faction_refs(self.user)
    add_user_to_new_faction(self.user)
  end

  private
  def add_user_to_new_faction(user)
    f = @instance.faction
    if f.update_boss(user)
      Factions::user_joins_faction(self.user, f.id)
      true
    else
      f.errors.each do |err|
        self.errors.add(*err)
      end
    end
  end

  def load_faction_refered_instance(options)
    if !%w(Game GamingPlatform).include?(options[:faction_type])
      raise 'Invalid faction type specified "%s"' % options[:faction_type]
    end
    cls = Object.const_get(options[:faction_type])
    field_id = "#{ActiveSupport::Inflector::singularize(ActiveSupport::Inflector::tableize(cls.name))}_id"
    instance = cls.find(options[field_id.to_sym].to_i)
    if instance.nil?
      raise "Unable to find refered object(#{options[:faction_type]}, #{options[field_id.to_sym]})"
    end

    if instance.has_faction?
      raise "#{options[:faction_type]} #{instance.name} already has a faction."
    end

    instance
  end

  def remove_old_faction_refs(user)
    fold = Faction.find_by_boss(user)
    fold.update_boss(nil) if fold
    fold = Faction.find_by_underboss(user)
    fold.update_underboss(nil) if fold
  end
end
