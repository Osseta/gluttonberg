# encoding: utf-8

module Gluttonberg
  module Admin
    module Membership
      class GroupsController < Gluttonberg::Admin::BaseController
        before_filter :find_group, :only => [:delete, :edit, :update, :destroy]
        before_filter :authorize_user , :except => [:edit , :update]
        drag_tree Group , :route_name => :admin_group_move
        
        def index
          @groups = Group.all.paginate(:page => params[:page] , :per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items") )
        end
  
        def new
          @group = Group.new
        end
  
        def create
          @group = Group.new(params[:gluttonberg_group])
          if @group.save
            flash[:notice] = "Group created!"
            redirect_to :action => :index
          else
            render :action => :new
          end
        end
        
        def edit          
        end
  
        def update
          if @group.update_attributes(params[:gluttonberg_group])
            flash[:notice] = "Member account updated!"
            redirect_to  :action => :index
          else
            flash[:notice] = "Failed to save account changes!"
            render :action => :edit
          end 
        end
        
        def delete
          display_delete_confirmation(
            :title      => "Delete “#{@group.name}” group?",
            :url        => admin_group_path(@group),
            :return_url => admin_groups_path  
          )        
        end
  
        def destroy
          if @group.destroy
            flash[:notice] = "Group deleted!"
            redirect_to :action => :index
          else
            flash[:error] = "There was an error deleting the group."
            redirect_to :action => :index
          end  
        end
  
       private
          def find_group
            @group = Group.find(params[:id])
            raise ActiveRecord::RecordNotFound  if @group.blank?
          end
          
          def authorize_user
            authorize! :manage, Group
          end
      
      end
    end
  end
end