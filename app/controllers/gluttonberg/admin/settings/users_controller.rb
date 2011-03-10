module Gluttonberg
  module Settings
    class Users < Gluttonberg::Application
      include Gluttonberg::AdminController
      
      before :find_user, :exclude => [:index, :new, :create]
      
      def index        
          @users = User.all_for_user(session.user)
          display @users
      end
  
      def show
        display @user
      end
  
      def new
        only_provides :html
        @user = User.new
        display @user
      end
  
      def edit
        only_provides :html
        display @user
      end
      
      def delete
        display_delete_confirmation(
          :title      => "Delete the user #{@user.name}?",
          :action     => slice_url(:user, @user),
          :return_url => slice_url(:users),
          :do_not_delete => (session.user.id == @user.id)
        )
      end
  
      def create
        params["gluttonberg::user"][:email] = params["gluttonberg::user"][:email].downcase
        @user = User.new(params["gluttonberg::user"])
        if @user.save
          redirect slice_url(:users), :message => {:notice => "User was successfully created"}
        else
          message[:error] = "User failed to be created"
          render :new
        end
      end
  
      def update
        params["gluttonberg::user"][:email] = params["gluttonberg::user"][:email].downcase
        if @user.update_attributes(params["gluttonberg::user"])
           redirect slice_url(:users)
        else
          display @user, :edit
        end
      end
  
      def destroy
        if @user.destroy
          redirect slice_url(:users)
        else
          raise InternalServerError
        end
      end
  
      
      private
      
      def find_user
        @user = User.get_for_user(session.user , params[:id])        
        raise NotFound unless @user
      end
  
    end
  end
end
