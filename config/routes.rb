Rails.application.routes.draw do
  
  mount_at = Gluttonberg::Engine.config.mount_at
  
  scope :module => 'Gluttonberg' do
    scope :module => 'Public' do
      match "/asset/:hash/:id(/:thumb_name)" => "public_assets#show" , :as => :public_asset
      match "/_public/page" => "pages#show"
      
      # Blog Stuff
      resources :blogs do      
        resources :articles do
          resources :comments
          get "preview"
        end
      end
      match "/mark_as_flag/:flaggable_type/:flaggable_id" => "flag#new" , :as => :mark_as_flag
      match "/save_mark_as_flag" => "flag#create" , :as => :save_mark_as_flag
      match "/articles/tag/:tag" => "articles#tag" , :as => :articles_by_tag
      match "/articles/unsubscribe/:reference" => "articles#unsubscribe" , :as => :unsubscribe_article_comments      
    end
    
    namespace :admin do
      root :to => "main#index"
      
      # Help
      match("/help/:module_and_controller/:page" => "help#show", :module_and_controller => %r{\S+} , :as => :help)
      
      scope :module => 'Content' do
        match "/flagged_contents" => "flag#index" , :as => :flagged_contents
        get '/flagged_contents/moderation/:id/:moderation' => "flag#moderation", :as => :flagged_contents_moderation 
        match 'content' => "main#index",      :as => :content
        resources :pages do
          get 'delete', :on => :member
          resources :page_localizations
          get 'edit_home' => "pages#edit_home", :as =>  :edit_home
          post 'update_home' => "pages#update_home", :as =>  :update_home        
        end
        
        get "pages_list_for_tinymce" => "pages#pages_list_for_tinymce" , :as => :pages_list_for_tinymce
        resources :blogs do
          get 'delete', :on => :member
          resources :articles do
            get 'delete', :on => :member
            resources :comments do
              get 'delete', :on => :member
              get 'moderation', :on => :member
            end
          end
        end
        match "/pages/move(.:format)" => "pages#move_node" , :as=> :page_move
      end
      
      # Settings
      scope :module => 'Settings' do
        match 'settings' => "main#index",      :as => :settings
        resources :locales do 
          get 'delete', :on => :member
        end
        
        resources :users do
          get 'delete', :on => :member
        end
        
        resources :generic_settings do 
          get 'delete', :on => :member
        end       
      end  
      
      scope :module => 'AssetLibrary' do
        # asset library related routes
          resources :assets do 
            get 'delete', :on => :member
          end
          match "library" => "assets#index" , :as => :library
          match "add_asset_using_ajax"  => "assets#ajax_new" , :as => :add_asset_using_ajax
          match "add_assets_in_bulk"  => "assets#add_assets_in_bulk" , :as => :add_assets_in_bulk
          match "create_assets_in_bulk"  => "assets#create_assets_in_bulk" , :as => :create_assets_in_bulk
          match "browser"  => "assets#browser" , :as => :asset_browser
          match "browse/:category/page/:page"  => "assets#category" , :as => :asset_category
          match "collections/:id/page/:page"  => "collections#show" , :as => :asset_collection
          resources :collections  do 
            get 'delete', :on => :member
          end       
      end
      
      resources :password_resets
      
      get "login" => "user_sessions#new"
      post "login" => "user_sessions#create"
      match "logout" => "user_sessions#destroy"
    end
  end
end
