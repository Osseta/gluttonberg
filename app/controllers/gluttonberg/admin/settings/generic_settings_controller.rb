# encoding: utf-8

module Gluttonberg
  module  Admin
    module Settings
      class GenericSettingsController < Gluttonberg::Admin::BaseController
        before_filter :find_setting, :only => [:delete, :edit, :update, :destroy]
        before_filter :require_super_admin_user 
        
        def index
          @settings = Setting.find(:all , :order => "row asc")
          @current_home_page_id  = Page.home_page.id unless Page.home_page.blank?
          @pages = Page.all
        end
              
        def new
          @setting = Setting.new
        end
    
        def edit
        end
    
        def create
          @setting = Setting.new(params["gluttonberg_setting"])
          count = Setting.all.length
          @setting.row = count + 1
          if @setting.save!
            redirect_to admin_generic_settings_path
          else
            message[:error] = "Setting failed to be created"
            render :new
          end
        end
    
        def update
          if params.has_key? "gluttonberg/setting"
            params[:gluttonberg_setting] = params["gluttonberg/setting"]
          end  
          if @setting.update_attributes(params[:gluttonberg_setting])
            if request.xhr?
              render :text => @setting.value
            else
              format.html redirect_to admin_generic_settings_path 
            end            
          else
            render :edit
          end
        end
      
        
        def delete
          display_delete_confirmation(
            :title      => "Delete “#{@setting.name}” setting?",
            :url        => admin_generic_setting_path(@setting),
            :return_url => admin_generic_settings_path 
          )
        end

        def destroy
          if @setting.destroy
            redirect_to admin_generic_settings_path
          else
            raise ActiveResource::ServerError
          end
        end
    
        private

        def find_setting
          @setting = Setting.find(params[:id]) 
          raise ActiveRecord::RecordNotFound  unless @setting
        end
    
      end # GenericSettings
    end # Settings
  end #admin  
end # Gluttonberg