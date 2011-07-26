module Gluttonberg
  # This defines a DSL for for creating page descriptions. Page descriptions 
  # are used to declare the page archetypes in an installation.
  # 
  # * Name & description
  # * Sections
  #   - Html
  #   - Plain text
  #   - Image  
  # * Redirections
  # * Rewrites to controllers
  #
  # It also provides access to any page descriptions that have been declared.
  class PageDescription
    @@_descriptions = {}
    @@_categorised_descriptions = {}
    @@_description_names = {}
    @@_home_page    = nil
    
    
    attr_accessor :options
    
    def initialize(name)
      @position = 0
      @options = {
        :name       => name,
        :home       => false,
        :behaviour  => :default,
        :layout     => "public",
        :view       => "default"
      }
      @sections = {}
      @@_descriptions[name] = self
    end
    
    %w(label view layout limit description).each do |opt|
      class_eval %{
        def #{opt}(opt_value)
          @options[:#{opt}] = opt_value
        end
      }
    end
    
    # This is a destructive method which removes all page definitions. Mainly
    # used for testing and debugging.
    def self.clear!
      @@_descriptions.clear
      @@_categorised_descriptions.clear
      @@_description_names.clear
      @@_home_page = nil
    end
    
    # This just loads the page_descriptions.rb file from the config dir.
    #
    # The specified file should contain the various page descriptions.
    def self.setup
      path = File.join(Rails.root, "config", "page_descriptions.rb")
      require path if File.exists?(path)
    end
    
    def self.add(&blk)
      class_eval(&blk)
    end
    
    # Define a page. This can be called directly, but is generally used inside
    # of an #add block.
    def self.page(name, &blk)
      new(name).instance_eval(&blk)
    end
    
    # Returns the definition for a specific page description.
    def self.[](name)
      # puts @@_descriptions
      # puts @@_descriptions[name.to_s.downcase.to_sym].options
      @@_descriptions[name.to_s.downcase.to_sym]
    end
    
    # Returns the full list of page descriptions as a hash, keyed to each
    # description’s name.
    def self.all
      @@_descriptions
    end
    
    # Returns all the descriptions with the matching behaviour in an array.
    def self.behaviour(name)
      @@_categorised_descriptions[name] ||= @@_descriptions.inject([]) do |memo, desc|
        memo << desc[1] if desc[1][:behaviour] == name
        memo
      end
    end
    
    # Collects all the names of the descriptions which have the specified 
    # behaviour.
    def self.names_for(name)
      @@_description_names[name] ||= self.behaviour(name).collect {|d| d[:name]}
    end
    
    # Returns the value the specified option — label, description etc.
    def [](opt)
      @options[opt]
    end
    
    # Returns the collection of sections defined for a page description.
    def sections
      @sections
    end
    
    def contains_section?(sec_name , type_name)
      @sections.each do |name, section|
        return true if sec_name.to_s == name.to_s && section[:type].to_s == type_name.to_s
      end
      false
    end
    
    # Set a description as the home page.
    def home(bool)
      @options[:home] = bool
      if bool
        @@_home_page = self
        @options[:limit] = 1
      elsif @@_home_page == self
        @@_home_page = nil
        @options.delete(:limit)
      end
    end
    
    # Sugar for defining a section.
    def section(name, &blk)
      new_section = Section.new(name , @position)
      #new_section.position = @position
      new_section.instance_eval(&blk)
      @sections[name] = new_section
      @position += 1
    end
    
    def top_level_page?
       @options[:name] == :top_level_page
    end
    
    def redirection_required?
      @options[:behaviour] == :rewrite
    end
    
    # Configures the page to act as a rewrite to named route. This doesn’t 
    # work like a rewrite in the traditional sense, since it is intended to be
    # used to redirect requests to a controller. Becuase of this it can't rewrite
    # to a path, it needs to use a named route.
    def rewrite_to(route)
      @rewrite_route = route
      @options[:behaviour] = :rewrite
    end

    # Allows us to check if this page needs to have a path rewritten to point
    # to a controller.
    def rewrite_required?
      @options[:behaviour] == :rewrite
    end
    
    # Returns the named route to be used when rewriting the request.
    def rewrite_route
      @rewrite_route
    end
    
    # Declare this description as a redirect. The redirect type can be:
    #
    # :remote - A full url to another domain
    # :block  - A block that will be evaluated and it’s return value will be 
    #           used to handle the redirect
    # :path   - The path to redirect to, hey, simple!
    # :page   - Allows the user to specify which other page they want to 
    #           redirect to.
    def redirect_to(type = nil, opt = nil, &blk)
      if block_given?
        @redirect_block = blk
        @redirect_type  = :block
      else
        @redirect_option  = opt if opt
        @redirect_type    = type
      end
      @options[:behaviour]  = :redirect
    end
    
    # Checks to see if the description has been defined as a redirect.
    def redirect?
      !@redirect_type.nil?
    end
    
    # Checks to see if this is home. Duh.
    def home?
      @options[:home]
    end
    
    # Returns the path that this description wants to redirect to. It accepts 
    # the current page — from which is extracts the redirect options — and the 
    # params for the current request.
    def redirect_url(page, params)
      case @redirect_type
        when :remote
          @redirect_option
        when :block
          @redirect_block.call(page, params)
        when :path
          Router.localized_url(redirect_value(page, params), params)
        when :page
          path_to_page(page, params)
      end
    end
    
    private
    
    # This method is used in conjunction with #redirect_url when a redirect to
    # another page has been specified. It finds and examines the specified page 
    # to figure out what it’s path is.
    def path_to_page(page, params)
      localization = PageLocalization.find(:first,
        :conditions => {
          :page_id  => page.redirect_target_id,
          :locale   => params[:locale]
        }  
      )
      raise ActiveRecord::RecordNotFound if localization.blank?
      localization.path
    end
    
    # This class is used to define the sections of content in a page 
    # description. This class should never be instantiated direction, instead
    # sections should be declared in the description DSL.
    class Section
      
      #attr_accessor :position
      
      def initialize(name , pos)
        @options = {:name => name, :limit => 1 , :position => pos}
        @custom_config = {}
      end
      
      %w(type limit label).each do |opt|
        class_eval %{
          def #{opt}(opt_value)
            @options[:#{opt}] = opt_value
          end
        }
      end
      
      # Stores additional configuration options, which can be used by arbitrary
      # code. Generally however it is intended to be used to provide 
      # configuration for the particular content class associated with this 
      # section.
      def configure(opts)
        @custom_config ||= {}
        @custom_config.merge!(opts)
      end
      
      # Returns the value for the specified option — name, description etc.
      def [](opt)
        @options[opt]
      end
      
      # Returns the custom configuration as a hash.
      def config
        @custom_config
      end
    end # Section
  end # PageDescription
end # Gluttonberg
