# This Class is intended to be used to integrate an arbitrary controller into
# the Gluttonberg front end. It provides access to the locale/dialect processing,
# templating, page collections for generating navigations and injects a bunch of
# other useful helpers.


class Gluttonberg::Public::BaseController < ActionController::Base
    # The included hook is used to create a bunch of class-ivars, which are used to
    # store various configuration options.
    #
    # It also installs before and after hooks that have been declared elsewhere
    # in this module.
    
    attr_accessor :page, :locale  
    before_filter :retrieve_locale    
    layout "public"
    
    helper_method :current_user_session, :current_user
    
    if Rails.env == "production"    
      rescue_from ActiveRecord::RecordNotFound, :with => :not_found
      rescue_from ActionController::RoutingError, :with => :not_found
    end
    
    before_filter :verify_site_access    
    
  protected
    
    def verify_site_access
      unless action_name == "restrict_site_access"
        setting = Gluttonberg::Setting.get_setting("restrict_site_access")
        if !setting.blank? && cookies[:restrict_site_access] != "allowed"
          if env['gluttonberg.page'].blank?
            redirect_to restrict_site_access_path(:return_url => request.url)
          else
            default_localization = Gluttonberg::PageLocalization.find(:first , :conditions => { :page_id => env['gluttonberg.page'].id , :locale_id => Gluttonberg::Locale.first_default.id } )
            redirect_to restrict_site_access_path(:return_url => default_localization.public_path)
          end  
        end
      end  
    end
    
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end

    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.record
    end

    def require_user
      unless current_user
        store_location
        flash[:error] = "You must be logged in to access this page"
        redirect_to login_url
        return false
      end
      true
    end
    
    def require_super_admin_user
      return false unless require_user
      
      unless current_user.super_admin?
        store_location
        flash[:notice] = "You dont have privilege to access this page"
        redirect_to admin_login_url
        return false
      end
    end
    
    def store_location
      session[:return_to] = request.request_uri
    end

    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end
      
    def retrieve_locale
      @locale = env['gluttonberg.locale']
    end
    
    # Exception handlers
    def not_found
      render :layout => "bare" , :template => 'gluttonberg/public/exceptions/not_found'
    end

    # handle NotAcceptable exceptions (406)
    def not_acceptable
      render :layout => "bare" , :template => 'gluttonberg/public/exceptions/not_acceptable'
    end
    
    def internal_server_error
      render :layout => "bare" , :template => 'gluttonberg/public/exceptions/internal_server_error'
    end

end