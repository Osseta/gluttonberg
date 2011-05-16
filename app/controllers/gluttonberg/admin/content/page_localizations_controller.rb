module Gluttonberg
  module Admin
    module Content
      class PageLocalizationsController < Gluttonberg::Admin::BaseController
        before_filter :find_localization, :exclude => [:index, :new, :create]
        before_filter :authorize_user 
        
        def edit
          @page_localization.navigation_label = @page_localization.page.navigation_label if @page_localization.navigation_label.blank?
          @page_localization.slug = @page_localization.page.slug  if @page_localization.slug.blank?
          @page_localization.save!
          @version = params[:version]  unless params[:version].blank?
          @page = @page_localization.page
        end

        def update
          @page_localization.contents.each do |content|
            content.updated_at = Time.now
          end
          if @page_localization.update_attributes(params["gluttonberg_page_localization"]) || !@page_localization.changed?            
            redirect_to admin_page_path(params[:page_id])
          else
            render :edit
          end
        end

        private
          def find_localization
            @page_localization = PageLocalization.find(params[:id])
            raise ActiveRecord::RecordNotFound  unless @page_localization
          end
          
          def authorize_user
            authorize! :manage, Gluttonberg::Page
          end
          
      end #class  
    end
  end  
end
