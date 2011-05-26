module Gluttonberg
  module Library
    # The attachment mixin encapsulates the majority of logic for handling and 
    # processing uploads. It exists here in a mixin rather than in the Asset
    # class purely because it is ultimately the intention to have a different 
    # Asset class for each major category of assets e.g. ImageAsset, 
    # DocumentAsset.
    
    #require "mp3info"
    
    module AttachmentMixin
     
      # Default sizes used when thumbnailing an image.
      DEFAULT_THUMBNAILS = {
        :small_thumb => {:label => "Small Thumb", :filename => "_thumb_small", :geometry => "110x75" },
        :large_thumb => {:label => "Large Thumb", :filename => "_thumb_large", :geometry => "250x200"},
        :jwysiwyg_image => {:label => "Thumb for jwysiwyg", :filename => "_jwysiwyg_image", :geometry => "250x200"}
      }
      
      # The default max image size. This can be overwritten on a per project 
      # basis via the rails configuration.
      MAX_IMAGE_SIZE = "2000x2000>" #Resize image to have specified area in pixels. Aspect ratio is preserved.
     
      def self.included(klass)
        klass.class_eval do
          
          after_destroy  :remove_file_from_disk
          before_save    :generate_reference_hash
          
          extend ClassMethods
          include InstanceMethods
          
        end
      end
      
      module ClassMethods


        # Generate auto titles for those assets without name
        def generate_name
          assets = Asset.find(:all , :conditions => { :name => "" } )
          assets.each do |asset|
            p asset.file_name
            asset.name = asset.file_name.split(".")[0]
            asset.save
          end
          'done' # this just makes the output nicer when running from slice -i
        end  
        
        # Returns a collection of thumbnail definitions — sizes, filename etc. — 
        # which is a merge of defaults and any custom thumbnails defined by the 
        # user.
        def sizes          
          @thumbnail_sizes ||= if Rails.configuration.thumbnails
            Rails.configuration.thumbnails.merge(DEFAULT_THUMBNAILS)
          else
            DEFAULT_THUMBNAILS            
          end
        end
        
        # Returns the max image size as a hash containing :width and :height.
        # May be the default, or the value configured for a particular project.
        def max_image_size          
          Rails.configuration.max_image_size || MAX_IMAGE_SIZE
        end
          
        
      end #ClassMethods
      
      
      module InstanceMethods
        
        # Setter for the file object. It sanatises the file name and stores in 
        # the filename property. It also sets the mime-type and size.
        def file=(new_file)
          unless new_file.blank?
            logger.info("\nFILENAME: #{new_file.original_filename} \n\n")
                          
            # Forgive me this naive sanitisation, I'm still a regex n00b            
            clean_filename = new_file.original_filename.split(%r{[\\|/]}).last
            clean_filename = clean_filename.gsub(" ", "_").gsub(/[^A-Za-z0-9\-_.]/, "").downcase

            # _thumb.jpg is a reserved name for the thumbnailing system, so if the user
            # has a file with that name rename it.
            if (clean_filename == '_thumb_small.jpg') || (clean_filename == '_thumb_large.jpg')
              clean_filename = 'thumb.jpg'
            end
            
            
            self.mime_type = new_file.content_type
            self.file_name = clean_filename
            self.size = new_file.size 
            @file = new_file
          end
        end
        
        # Returns the file assigned by file=
        def file
          @file
        end
        
        # Returns the public URL to this asset, relative to the domain.
        def url
          "/assets/#{asset_hash}/#{file_name}"
        end
        
        def asset_folder_path
          "/assets/#{asset_hash}"
        end
        
        # Returns the URL for the specified image size.
        
        def url_for(name)
            if self.class.sizes.has_key? name
              filename = self.class.sizes[name][:filename]
              "/assets/#{asset_hash}/#{filename}.jpg"
            end  
        end

        # Returns the public URL to the asset’s small thumbnail — relative 
        # to the domain.
        def thumb_small_url
          url_for(:small_thumb) if category.downcase == "image"       
        end
        
        # Returns the public URL to the asset’s large thumbnail — relative 
        # to the domain.
        def thumb_large_url
          url_for(:large_thumb) if category.downcase == "image"           
        end
        
        def url_for_processed_video
          "/assets/#{asset_hash}/processed_#{self.filename_without_extension}.mp4"
        end
        
        
                        
                
        # Returns the full path to the file’s location on disk.
        def location_on_disk
          directory + "/" + file_name
        end
        
        # In the case where an uploaded image has been larger that the 
        # specified max-size and consequently resized, this method will provide
        # the path to the original, un-altered file.
        def original_file_on_disk
          directory + "/original_" + file_name
        end

        # The generated directory where this file is located. If it is an image
        # it’s thumbnails will be stored here as well.
        def directory
          Library.setup            
          Library.root + "/" + self.asset_hash
        end
        
        # Create thumbnailed versions of image attachements.
        # TODO: generate thumbnails with the correct extension
        def generate_image_thumb
                    
          begin            
            
            self.class.sizes.each_pair do |name, config|
              #image = QuickMagick::Image.read(location_on_disk).first
              begin                
                image = QuickMagick::Image.read(original_file_on_disk).first
              rescue
                image = QuickMagick::Image.read(location_on_disk).first
              end
              
              path = File.join(directory, "#{config[:filename]}.jpg")
              image.resize config[:geometry]
              image.save path           
            end 
          
            update_attribute( :custom_thumbnail , true)         
          rescue => e
            update_attribute( :custom_thumbnail , false)   
          end    
          
        end  
        
        def generate_proper_resolution
          
            begin
              make_backup
              begin                
                image = QuickMagick::Image.read(original_file_on_disk).first
              rescue => e
                image = QuickMagick::Image.read(location_on_disk).first
              end  
              image.resize self.class.max_image_size
              image.save File.join(directory, file_name)    
              # remove mp3 info if any image have. it may happen in the case of updating asset from mp3 to image
                audio = AudioAssetAttribute.find( :first , :conditions => {:asset_id => asset.id})
                audio.destroy                              
            rescue #TypeError => error
              # ignore TypeErrors, just means it wasn't a supported image
              update_attribute( :custom_thumbnail , false) 
            end
        end
                

        # Generates thumbnails for images, but also additionally checks to see 
        #TODO if the uploaded image exceeds the specified maximum, in which case it will resize it down.
        def generate_thumb_and_proper_resolution(asset)          
              asset.generate_proper_resolution              
              asset.generate_image_thumb
        end
        
        

        #TODO Collect mp3 files info using Mp3Info gem        
        def collect_mp3_info(asset)
          audio = AudioAssetAttribute.find( :first , :conditions => {:asset_id => asset.id})
          
          begin
              #open mp3 file
              Mp3Info.open(location_on_disk) do |mp3|
                                
                if audio.blank?
                  #, :genre => mp3.genre 
                  AudioAssetAttribute.create( :asset_id => asset.id , :length => mp3.length , :title => mp3.tag.title , :artist => mp3.tag.artist , :album => mp3.tag.album , :tracknum => mp3.tag.tracknum)
                else
                  audio.update_attributes( {:length => mp3.length, :genre =>"" , :title => mp3.tag.title , :artist => mp3.tag.artist , :album => mp3.tag.album , :tracknum => mp3.tag.tracknum })
                end 
                                 
              end
            
          rescue => detail            
            # if exception occurs and asset has some attributes, then remove them.
            unless audio.blank?
              audio.update_attributes( {:length => nil , :title => nil , :artist => nil , :album => nil , :tracknum => nil })
            end  
          end
          
        end
        
        def asset_processing
          asset_id_to_process = self.id  
          asset = Asset.find(:first , :conditions => { :id => asset_id_to_process } )
          if asset
              #if it is an image, then create a thumbnail
              if asset.asset_type.asset_category.name == "image"
                                        
                generate_thumb_and_proper_resolution(asset)                
              elsif asset.asset_type.asset_category.name == "audio"
              # if its mp3 file, collect its sound info
                collect_mp3_info(asset)
                Delayed::Job.enqueue AudioJob.new(asset.id)
              elsif asset.asset_type.asset_category.name == "video"
                Delayed::Job.enqueue VideoJob.new(asset.id)
              end
          end
          
        end  
        
        
        private

        def make_backup
          unless File.exist?(original_file_on_disk)
            FileUtils.cp location_on_disk, original_file_on_disk
            FileUtils.chmod(0755,original_file_on_disk)
          end  
        end
                

        def remove_file_from_disk
          if File.exists?(directory)
            FileUtils.rm_r(directory)
          end
        end

        def update_file_on_disk
          if file
            FileUtils.mkdir(directory) unless File.exists?(directory)
            FileUtils.cp file.tempfile.path, location_on_disk
            FileUtils.chmod(0755, location_on_disk)
            
            #  new file has been upload, if its image generate thumbnails, if mp3 collect sound info.
            asset_processing            
          end
        end

        def generate_reference_hash
          unless self.asset_hash
            self.asset_hash = Digest::SHA1.hexdigest(Time.now.to_s + file_name) 
          end
        end
      end
    end # AttachmentMixin
  end #Library  
end # Gluttonberg
