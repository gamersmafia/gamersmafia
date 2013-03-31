# -*- encoding : utf-8 -*-
module CanHaveFaction
  def self.included(base)
    base.extend AddHasMethod
  end

  module AddHasMethod
    def can_have_faction
      scope :without_faction, :conditions => "has_faction = 'f'"

      class_eval <<-END
        include CanHaveFaction::InstanceMethods
      END
    end
  end

  module InstanceMethods
    def create_contents_categories
      # El orden es importante

      field_id = "#{ActiveSupport::Inflector::singularize(ActiveSupport::Inflector::tableize(self.class.name))}_id"
      root_term = Term.find(
          :first,
          :conditions => ["#{field_id} = ? and taxonomy = '#{self.class.name}'",
                          self.id])
      if root_term.nil?
        root_term = Term.create({
            field_id.to_sym => self.id,
            :name => self.name,
            :slug => self.slug,
            :taxonomy => self.class.name,
        })
        if root_term.new_record?
          raise (
            "Cannot create new term for #{self.class.name} (id: #{self.id}):" +
            " #{root_term.errors.full_messages_html}")
        end
      end

      Organizations::DEFAULT_CONTENTS_CATEGORIES.each do |c|
        if root_term.children.find(
            :first, :conditions => ["name = ? AND taxonomy = ?", c[1], c[0]]).nil?
          root_term.children.create(:name => c[1], :taxonomy => c[0])
        end
      end
    end

    def create_faction
      f = Faction.find_by_name(self.name)
      if f.nil? then
        f = Faction.new(:name => self.name, :code => self.slug)
        if !f.save
          raise "Error creating faction: #{f.errors.full_messages_html}"
        end
      end

      slug = self.slug
      while Portal.find_by_code(slug) || Portal::UNALLOWED_CODES.include?(slug)
        slug += '1'
      end

      portal = Portal.create(:name => self.name, :code => slug)
      portal.factions<< f

      self.update_attribute(:has_faction, true)
    end
  end
end

ActiveRecord::Base.send :include, CanHaveFaction
