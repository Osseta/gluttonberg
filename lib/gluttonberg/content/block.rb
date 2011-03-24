module Gluttonberg
  module Content
    # This module can be mixed into a class to make it behave like a content 
    # block. A content block is a class that can be associated with a section
    # on in a page description.
    module Block
      # This included hook is used to declare the various properties and class
      # ivars we need.
      def self.included(klass)
        
        puts "-------------------- just before register #{klass} "
        
        klass.class_eval do
          extend Block::ClassMethods
          include Block::InstanceMethods
          
          #include Textilized
          
          class << self; attr_accessor :localized, :label, :content_type, :association_name end
          @localized = false
          
          attr_reader :current_localization
          
          # property :orphaned,     ::DataMapper::Types::Boolean, :default => false
          #           property :section_name, String
          #           property :created_at,   Time
          #           property :updated_at,   Time
          
          belongs_to :page
          
          # Generate the various names to be used in associations
          # type = Extlib::Inflection.underscore(Extlib::Inflection.demodulize(self.name))
          type = self.name.demodulize.underscore
          self.association_name = type.pluralize.to_sym
          self.content_type = type.to_sym
          # Let's generate a label from the class — this might be over-ridden later
          #self.label = Extlib::Inflection.humanize(type)
          self.label = type.humanize
        end
        
        # This registers this class so that the page can later query which 
        # classes it needs to be aware of.
        puts "-------------------- just before register #{klass} "
        Gluttonberg::Content.register_as_content(klass)
      end
    
      module ClassMethods
        # This declaration is used to create properties on a model which need 
        # to be localized. It does this by generating a localized class and
        # association. 
        #
        # It also registers the class as being localized.
        def is_localized(&blk)
          self.localized = true
        
          # Generate the localization model
          # class_name = "#{Extlib::Inflection.demodulize(self.name)}Localization"
          #           storage_name = Extlib::Inflection.tableize(class_name)
          #           localized_model = DataMapper::Model.new(storage_name)
          class_name = "#{self.name.demodulize}Localization"
          storage_name = "gb_#{class_name.tableize}"
          localized_model = Class.new(ActiveRecord::Base) #DataMapper::Model.new(storage_name)
          foreign_key = self.name.foreign_key
          puts "---------table name for localization is  #{storage_name}"
          localized_model.set_table_name(storage_name)
          Gluttonberg.const_set(class_name, localized_model)
        
          # Mix in our base set of properties and methods
          localized_model.send(:include, Gluttonberg::Content::BlockLocalization)
          #localized_model.send(:include, Gluttonberg::Content::Textilized)
          # Generate additional properties from the block passed in
          localized_model.class_eval(&blk)
          # Store the name so we can easily access it without having to look 
          # at this parent class
          localized_model.content_type = self.content_type
        
          # Set up filters on the class to make sure the localization gets migrated
          #self.after_class_method(:auto_migrate!) { localized_model.auto_migrate! }
          #self.after_class_method(:auto_upgrade!) { localized_model.auto_upgrade! }
          
          # Tell the content module that we are localized
          #localized_model.association_name = :"#{self.content_type}_localizations"
          Gluttonberg::Content.register_localization( "#{self.content_type}_localizations".to_sym , localized_model)
        
          # Set up the associations
          has_many :localizations, :class_name => Gluttonberg.const_get(class_name).to_s  , :foreign_key => "html_content_id"
          localized_model.belongs_to(:parent, :class_name => self.name , :foreign_key => "html_content_id")
          
          puts "----#{"#{self.content_type}_localizations".to_sym}-----------#{self.name}-------- end of is_localized method #{Gluttonberg.const_get(class_name)}"
        end
        
        # Does this class have an associated localization class.
        def localized?
          self.localized
        end
        
        # Returns all the matching models with the specificed localization loaded.
        def all_with_localization(opts)
          page_localization_id = opts.delete(:page_localization_id)
          results = all(opts)
          results.each { |r| r.load_localization(page_localization_id) }
          results
        end
      end
      
      module InstanceMethods
        # Returns the section this content instance is associated with. It does 
        # this by looking at the associated page, it’s description then the 
        # matching section.
        def section
          @section ||= page.description.sections[section_name.to_sym]
        end
        
        # Checks to see if this content class has localized properties.
        def localized?
          self.class.localized?
        end
        
        # The name of the generated association. This is the association that 
        def association_name
          self.class.association_name
        end
        
        # def section_name
        #           section[:name]
        #         end
                
        def section_label
          section[:label]
        end
        
        # Content type is simply the inflected version of the content class 
        # name, e.g. FooContent becomes :foo_content
        def content_type
          self.class.content_type
        end
        
        # Loads a localized version based on the specified page localization,
        # then stashes it in an accessor
        def load_localization(id_or_model)
          if localized?
            localization_id = id_or_model.is_a?(Numeric) ? id_or_model : id_or_model.id
            conditions = {:page_localization_id => localization_id, :"#{self.class.content_type}_id" => id}
            @current_localization = localizations.first(conditions)
          end
        end
      end
    end
  end
end