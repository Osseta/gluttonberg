module Gluttonberg
  module Public
    class PagesController < Gluttonberg::Public::BaseController
      before_filter :retrieve_page , :only => [ :show ]
      
      # If localized template file exist then render that file otherwise render non-localized template
      def show
        if Gluttonberg::Member.enable_members == true
          return unless require_member
          unless current_member.does_member_have_access_to_the_page?( page)
            raise CanCan::AccessDenied
          end  
        end
        
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
      
      def restrict_site_access
        setting = Gluttonberg::Setting.get_setting("restrict_site_access")
        if setting == params[:password]
          cookies[:restrict_site_access] = "allowed"
          redirect_to( params[:return_url] || "/")
          return
        else
          cookies[:restrict_site_access] = ""  
        end
        render :layout => false
      end
      
      private 
        def retrieve_page
          @page = env['gluttonberg.page']
          unless( current_user &&( authorize! :manage, Gluttonberg::Page) )
            @page = nil unless @page.published?
          end
          raise ActiveRecord::RecordNotFound  if @page.blank?
        end
      
    end
  end
end
