module Hyhull::FullTextIndexableBehaviour  
  extend ActiveSupport::Concern

  included do
    logger.info("Adding Hyhull::FullTextIndexableBehaviour to the Hydra model")
  end

  # This method will generate a fullText datastream for resources that have valid 'full textable' content
  # The full text will be stored in a datastream on same asset as the content 
  # Returns true if the full_text_datastream is generated
  def generate_full_text_datastream
  	# Get primary content ds details from contentMetadata    
    ds, obj = primary_content_ds_and_object
    if !ds.nil? && full_text_extractable?(ds)
      text = extract_text_from_datastream(ds)      
      unless text.empty?
        obj.datastreams["fullText"].content = text
        obj.datastreams["fullText"].mimeType = "text/plain"
        # We save it if its a FileAsset, otherwise leave saving to the calling class
        obj.save if obj.class == FileAsset
        return true
      end 
    end

    return false
  end

  # This method will return the Full text datastream 
  def full_text_datastream
  	# The full_text is stored within a datastream in the primary_content object
    ds, obj = primary_content_ds_and_object

    unless obj.nil?
      if obj.datastreams["fullText"] && obj.datastreams["fullText"].has_content?
        return obj.datastreams["fullText"]
      end
    end
    return nil
  end

  def primary_content_ds_and_object
    # ContentMetadata contains self referencing identifiers, therefore the self needs to be persisted before checking for content
    if self.persisted? && self.respond_to?("contentMetadata") && self.respond_to?(:get_resource_metadata_by_sequence_no)
      # At the moment, we index the primary (1) ds of a resource
      content_hash = self.get_resource_metadata_by_sequence_no("1")
      
      # If content_has nil the resource has no content
      if content_hash.nil?
         return nil, nil 
      else
        if self.id == content_hash[:asset_id]
          return self.datastreams[content_hash[:datastream_id]], self
        else
        	# Generally a GenericParent resource
          if self.respond_to? :file_assets
            file_asset_index = self.file_assets.rindex{ |file_asset| file_asset.id == content_hash[:asset_id] }
          
            unless file_asset_index.nil? 
              return self.file_assets[file_asset_index].datastreams[content_hash[:datastream_id]], self.file_assets[file_asset_index]
             end
          end
        end
      end
    end
    return nil, nil
  end

  def to_solr(solr_doc={}, opts={})
  	# Pass through the solr_doc to superclass
    super(solr_doc, opts)
    solr_doc["full_text_ti"] = full_text_datastream.content unless full_text_datastream.nil?
    return solr_doc
  end

  private

  # This method calls the TextExtractionSerice method to extract text from datastream content 
  def extract_text_from_datastream(ds)
    text = ""
    begin 
      text = Hyhull::Services::TextExtractionService.extract_text(ds.content, ds.mimeType)
      return text
    rescue
       logger.warn("Rescue from text extraction service exception. Failed to extract text from #{ds.pid} datastream #{ds.dsid}")
       # Perhaps e-mail??
       return text
    end
  end

  # Should full text be extracted from the ds...
  def full_text_extractable?(ds)
    ds.mimeType == "application/pdf"
  end

 end
