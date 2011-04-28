require 'gluttonberg'
require 'rails'

module Gluttonberg
  class Engine < Rails::Engine
    
    # Config defaults
    config.widget_factory_name = "default factory name"
    config.mount_at = '/'
    config.admin_path = '/admin'
    config.app_name = 'Gluttonberg 1.0'
    config.localize = true
    config.active_record.observers = ['gluttonberg/page_observer' , 'gluttonberg/page_localization_observer' , 'gluttonberg/locale_observer' ]
        
    config.thumbnails = {   }
    config.max_image_size = "1600x1200>"
    config.encoding = "utf-8"
    config.gluttonberg = {}
    config.identify_locale = :prefix
    config.host_name = "localhost:3000"
    config.user_roles = [] # User model always concat following two roles ["superadmin" , "admin"]
    config.honeypot_field_name = "gluttonberg_honeypot"
    
    # Load rake tasks
    rake_tasks do
      load File.join(File.dirname(__FILE__), 'rails/railties/tasks.rake')
      load File.join(File.dirname(__FILE__), 'gluttonberg/tasks/asset.rake')
      load File.join(File.dirname(__FILE__), 'gluttonberg/tasks/page.rake')
    end
    
    # Check the gem config
    initializer "check config" do |app|

      # make sure mount_at ends with trailing slash
      config.mount_at += '/'  unless config.mount_at.last == '/'
    end

    initializer "static assets" do |app|
      app.middleware.use ::ActionDispatch::Static, "#{root}/public"
    end

    initializer "middleware" do |app|
      app.middleware.use Gluttonberg::Middleware::Locales
      app.middleware.use Gluttonberg::Middleware::Rewriter
      app.middleware.use Gluttonberg::Middleware::Honeypot , config.honeypot_field_name
    end
      

    initializer "setup gluttonberg components" do |app| 
      Gluttonberg::Content::Versioning.setup
      Gluttonberg::PageDescription.setup
      
      # register content class here. It is required for lazyloading environments.
      Gluttonberg::Content::Block.register(Gluttonberg::PlainTextContent)
      Gluttonberg::Content::Block.register(Gluttonberg::HtmlContent)
      Gluttonberg::Content::Block.register(Gluttonberg::ImageContent)
         
      Gluttonberg::Content.setup      
      
      Gluttonberg.laod_settings_from_db
      
    end
    
    initializer "setup gluttonberg asset library" do |app| 
      Gluttonberg::Library.setup     
      require "acts-as-taggable-on" 
    end
    
  end
end
