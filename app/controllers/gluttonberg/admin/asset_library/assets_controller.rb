module Gluttonberg
  module Admin
    module AssetLibrary
      class AssetsController < Gluttonberg::Admin::ApplicationController

        before_filter :prepare_to_edit  , :except => [:category , :show , :delete , :create , :update  ]
        #before_filter :merge_operator_with_content , :only => [:create , :update , :create_assets_in_bulk ]
    
        
        # home page of asset library
        def index
          # Get the latest assets, ensuring that we always grab at most 15 records      
          @assets = Asset.find(:all, :conditions => { :updated_at => ((Time.now - 24.hours).gmtime)..(Time.now.gmtime)  }, :limit => 15 , :order => "updated_at" )
          @categories = AssetCategory.all  # all categories for categories tab
        end
    
        # if filter param is provided then it will only show filtered type    
        def browser
          @assets = []
          @category_filter = ( params[:filter].blank? ? "all" : params[:filter] )
          if @category_filter == "all"
            @categories = AssetCategory.all
          else
            @categories = AssetCategory.find(:all , :conditions => { :name => @category_filter })
          end
      
          @photoseries = PhotoSequence.all
          @sets = SetSequence.all
          @html_contents = HtmlContent.all
          @show_bigstories_contents = ( params[:show_content].blank? ? false : params[:show_content] )
          @films = Film.all
      
      
          if params["no_frame"]
            render :partial => "browser_root" , :locals => {:show_content => @show_bigstories_contents}
          else
            render :layout => false
          end
        end
    
        # list assets page by page if user drill down into a category from category tab of home page
        def category
          conditions = {:order => get_order, :per_page => 20 , :page => params[:page]}
          if params[:category] == "all" then
            @assets = Asset.paginate( conditions ) # if ignore asset category if user selects 'all' from category
          else
            req_category = AssetCategory.first(:conditions => "name = '#{params[:category]}'" )
            # if category is not found then raise exception
            if req_category.nil?
              render :template => '/layouts/not_found', :status => 404 , :locals => { :message => "Asset category you are looking for is not found."}
            else
              @assets = req_category.assets.paginate( conditions )                   
            end          
          end # category#all      
        end
    
    
        def show
          # if asset not found stop the execution of the action and render not found error
          return unless find_asset
          #render :layout => "admin/application"
        end
    
        # add assets from zip folder    
        def add_assets_in_bulk
          @asset = Asset.new
          #render :layout => "admin/application"
        end
    
        # create assets from zip
        def create_assets_in_bulk
          @new_assets = []
          if request.post?
        
            # process new asset_collection and merge into existing collections
            process_new_collection_and_merge(params)
            @asset = Asset.new(params[:asset])       
        
            if @asset.valid?
                  open_zip_file_and_make_assets()             
                  if @new_assets.blank?
                    flash[:error] = "Zip folder you have provided does not have any valid file!"
                    prepare_to_edit
                    render :action => :add_assets_in_bulk                
                  else
                    flash[:notice] = "All valid assets are saved successfully!"                
                  end
            else
              prepare_to_edit
              flash[:error] = "Asset you have provided is not valid!"
              render :action => :add_assets_in_bulk      
            end          
          end
        end
    
        # new asset
        def new
          @asset = Asset.new
          #render :layout => "admin/application"
        end
            
        # edit asset        
        def edit
          # if asset not found stop the execution of the action and render not found error
          return unless find_asset
          #render :layout => "admin/application"
        end
    
        # delete asset
        def delete
          # if asset not found stop the execution of the action and render not found error
          return unless find_asset      
        end
    
        # create individual asset
        def create      

          # process new asset_collection and merge into existing collections
          process_new_collection_and_merge(params)

          @asset = Asset.new(params[:asset])       
          if @asset.save
            flash[:notice] = "Asset created successfully!"
            redirect_to(edit_admin_asset_url(@asset))
          else
            prepare_to_edit
            render :new
          end
        end
    
        # update asset
        def update
      
          # if asset not found stop the execution of the action and render not found error
          return unless find_asset
      
          # process new asset_collection and merge into existing collections
          process_new_collection_and_merge(params)
      
          if @asset.update_attributes(params[:asset])
            flash[:notice] = "Asset updated successfully!"
            redirect_to(admin_asset_url(@asset))
          else
            prepare_to_edit
            flash[:error] = "Asset updatation failed!"
            render :edit
          end
        end
    
        # destroy an indivdual asset
        def destroy
          # if asset not found stop the execution of the action and render not found error
          return unless find_asset
          if @asset.destroy
            flash[:notice] = "Asset destroyed successfully!"
          else
            flash[:error] = "Failed to destroy asset!"
          end
          redirect_to :action => :index
        end
    
    
    
        private
    
            def find_asset
              @asset = Asset.find(:first , :conditions => { :id => params[:id] } )   
              if @asset.blank?
                render :template => '/layouts/not_found', :status => 404 , :locals => { :message => "The asset you are looking for is not exist."}
                return false
              end         
              true
            end
    
            def prepare_to_edit
              @collections = AssetCollection.all( :order => "name")
            end
    
     
            # if new collection is provided it will create the object for that
            # then it will add new collection id into other existing collection ids     
            def process_new_collection_and_merge(params)
              the_collection = find_or_create_asset_collection_from_hash(params["new_collection"])
               unless the_collection.blank?
                 params[:asset][:asset_collection_ids] = params[:asset][:asset_collection_ids] || []
                 unless params[:asset][:asset_collection_ids].include?(the_collection.id.to_s)
                   params[:asset][:asset_collection_ids] <<  the_collection.id 
                 end
               end
            end  
     
             # Returns an AssetCollection (either by finding a matching existing one or creating a new one)
             # requires a hash with the following keys
             #   do_new_collection: If not present the method returns nil and does nothing
             #   new_collection_name: The name for the collection to return.
             def find_or_create_asset_collection_from_hash(param_hash)
               # Create new AssetCollection if requested by the user
               if param_hash         
                   if param_hash.has_key?('new_collection_name')
                     unless param_hash['new_collection_name'].blank?
                       #create options for first or create
                       options = {:name => param_hash['new_collection_name'] }
                 
                       # Retireve the existing AssetCollection if it matches or create a new one                  
                       the_collection = AssetCollection.find(:first , :conditions => options)
                       unless the_collection
                         the_collection = AssetCollection.create(options)
                       end 

                       the_collection                    
                     end # new_collection_name value
                   end # new_collection_name key
                 end # param_hash 
             end # find_or_create_asset_collection_from_hash
         
   
            # makes a new folder (name of the folder is current time stamp) inside tmp folder
            # open zip folder
            # iterate on opened zip folder and make assets for each entry using  make_asset_for_entry method
            # removes directory which we made inside tmp folder
            # also removes zip tmp file
            def open_zip_file_and_make_assets
      
                zip = params[:asset][:file]
                dir = File.join(RAILS_ROOT,"tmp")
                dir = File.join(dir,Time.now.to_i.to_s)                
        
                FileUtils.mkdir_p(dir)              
        
                begin
                  Zip::ZipFile.open(zip.tempfile.path).each do |entry|
                    make_asset_for_entry(entry , dir)                  
                  end                
                  zip.tempfile.close
                rescue => e
                  puts "------------------------------------"
                  puts e
                end                
                FileUtils.rm_r(dir)
                FileUtils.remove_file(zip.tempfile.path)    
            end
      
            # taskes zip_entry and dir path. makes assets if its valid then also add it to @new_assets list
            # its responsible of extracting entry and its deleting it.
            # it use file name for making asset.
            def make_asset_for_entry(entry , dir)
                begin  
                  filename = File.join(dir,entry.name)
        
                  unless entry.name.starts_with?("._") || entry.name.starts_with?("__") || entry.directory?
                    entry.extract(filename)
                    file = MyFile.init(filename , entry)            
                    asset_name_with_extention = entry.name.split(".").first
                    asset = Asset.new(params[:asset].merge( :name => asset_name_with_extention ,  :file => file ) )
                    @new_assets << asset if asset.save
                    file.close
                    FileUtils.remove_file(filename)            
                  end
                rescue => e
                    puts "---------------make_asset_for_entry---------------------"
                    puts e
                end  
            end
        
        
            # def merge_operator_with_content
            #              params[:asset].merge!( :operator => current_user )
            #            end
            
            

      end # controller
    end  
  end  
end
# i made this class for providing extra methods in file class. 
# I am using it for making assets from zip folder. 
# keep in mind when we upload asset from browser, browser injects three extra attributes (that are given in MyFile class)
# but we are adding assets from file, i am injecting extra attributes manually. because asset library assumes that file has three extra attributes
class MyFile < File
  attr_accessor :original_filename , :content_type , :size
  
  def self.init(filename , entry)
    file = MyFile.new(filename) 
    file.original_filename = filename
    file.content_type = find_content_type(filename)
    file.size = entry.size
    file
  end  
  
  def tempfile
    self
  end
  def self.find_content_type(filename)
    begin
     MIME::Types.type_for(filename).first.content_type 
    rescue
      ""
    end
  end
  
end  