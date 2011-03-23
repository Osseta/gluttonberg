module Gluttonberg
  class Asset < ActiveRecord::Base
      set_table_name "gb_assets"
      has_many :set_elements, :as => :element
  
      after_save  :update_file
      before_validation  :set_category_and_type
            
      include Library::AttachmentMixin
        
      has_and_belongs_to_many :asset_collections     , :join_table => "gb_asset_collections_assets"
      belongs_to  :asset_type  
      has_one :audio_asset_attribute , :dependent => :destroy
 
 
      # constants for formatted file size
      GIGA_SIZE = 1073741824.0
      MEGA_SIZE = 1048576.0
      KILO_SIZE = 1024.0
    
 
      # returns category of asset
      def category
        if asset_type.nil? then
          Library::UNCATEGORISED_CATEGORY
        else
          asset_type.asset_category.name
        end
      end
    
      def title
        self.name
      end
    
      def type_name
        if asset_type.nil? then
          Library::UNCATEGORISED_CATEGORY
        else
          asset_type.name
        end
      end
    
      def formatted_file_size
        precision = 2
        unless size.blank?
          case
                when size == 1 : "1 Byte"
                when size < KILO_SIZE : "%d Bytes" % size
                when size < MEGA_SIZE : "%.#{precision}f KB" % (size / KILO_SIZE)
                when size < GIGA_SIZE : "%.#{precision}f MB" % (size / MEGA_SIZE)
                else "%.#{precision}f GB" % (size / GIGA_SIZE)
          end
        end  
      end

      def auto_set_asset_type
        self.asset_type = AssetType.for_file(mime_type, file_name)
        cat = self.category.to_s.downcase
        if cat == "image"
          self[:type]  = "Photo"
        elsif cat == "video"
          self[:type]  = "Video"
        end     
      end

      def self.refresh_all_asset_types
        all.each do |asset|
          asset.auto_set_asset_type
          asset.save
        end
      end

      def self.clear_all_asset_types
        all.each do |asset|
          asset.asset_type = nil
          asset.save
        end
      end
    
      # find out and set type and category of file
      def set_category_and_type      
        unless file.nil?
          auto_set_asset_type        
        end
      end
    
      def absolute_file_path
        Rails.root.to_s + "/public" + self.url.to_s
      end
    
      def filename_without_extension
        self.file_name.split(".").first unless self.file_name.blank?
      end
    
      def self.create_assets_from_ftp
      
        collection = AssetCollection.find_by_name("BULKS")
      
        files = Dir.entries(RAILS_ROOT+"/bulks")
        files.each do |entry|
          unless entry.starts_with?(".") || entry.starts_with?("__")   
            file = MyFile2.init(entry)            
            asset_name_with_extention = entry.split(".").first
        
            asset_params = {:name => asset_name_with_extention  , :file => file  }
            @asset = Asset.create(asset_params.merge({:asset_collection_ids => collection.id.to_s}))              
          end  
        end  
      end
      
    
      private
    
      # make a new asset folder if not exist. then make backup of asset. generate thumbnails 
      def update_file
        update_file_on_disk
      end


  end



  # i made this class for providing extra methods in file class. 
  # I am using it for making assets from zip folder. 
  # keep in mind when we upload asset from browser, browser injects three extra attributes (that are given in MyFile class)
  # but we are adding assets from file, i am injecting extra attributes manually. because asset library assumes that file has three extra attributes
  class MyFile2 < File
    attr_accessor :original_filename , :content_type , :size

    def self.init(filename)
      file = MyFile2.new(RAILS_ROOT+"/bulks/" + filename) 
      file.original_filename = filename
      file.content_type = find_content_type(filename)
      file.size = File.size(RAILS_ROOT+"/bulks/" + filename)
      file
    end  

    def self.find_content_type(filename)
      begin
       MIME::Types.type_for(filename).first.content_type 
      rescue
        ""
      end
    end

  end
  
end  