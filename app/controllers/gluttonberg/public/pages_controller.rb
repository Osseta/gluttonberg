module Gluttonberg
  module Public
    class PagesController < Gluttonberg::Public::BaseController
      before_filter :retrieve_page
      
      # If localized template file exist then render that file otherwise render non-localized template
      def show
        template = page.view
        template_path = "pages/#{template}" 
        
        if File.exists?(File.join(Rails.root,  "app/views/pages/#{template}.#{locale.slug}.html.haml" ) )
          template_path = "pages/#{template}.#{locale.slug}"
        end  
        
        # do not render layout for ajax requests
        if request.xhr?
          render :template => template_path, :layout => false
        else
          render :template => template_path
        end
      end
      
      private 
        def retrieve_page
          @page = env['gluttonberg.page']
          raise ActiveRecord::RecordNotFound  if @page.blank?
        end
      
    end
  end
end
