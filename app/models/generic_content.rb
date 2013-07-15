# app/models/generic_content.rb
# Fedora object for the Generic content type
class GenericContent < ActiveFedora::Base
  include Hydra::ModelMethods
  include Hyhull::ModelMethods
  include Hyhull::GenericContentBehaviour
  include Hyhull::ContentMetadataBehaviour
  include Hyhull::ResourceWorkflowBehaviour
  include Hyhull::Validators 

  # Extra validations for the resource_state state changes
  GenericContent.state_machine :resource_state do   
    state :hidden, :deleted do
      validates :resource_status, presence: true
    end

    state :qa, :published do
      validates :title, presence: true
    end

  end

 # before_save :apply_additional_metadata 

  has_metadata name: "descMetadata", label: "MODS metadata", type: Datastream::ModsGenericContent
  has_metadata name: "rightsMetadata", label: "Rights metadata" , type: Hydra::Datastream::RightsMetadata

  # Delagating to the terms to save clashes with the related_web_url
  delegate :primary_display_url, to: "descMetadata", :at =>[:mods, :location_element, :primary_display], unique: true
  delegate :raw_object_url, to: "descMetadata", :at =>[:mods, :location_element, :raw_object], unique: true

  #Delegate these attributes to the respective datastream
  #Unique fields
  delegate_to :descMetadata, [:title, :date_valid, :subject_geographic, :subject_temporal, :location_coordinates, :location_label, :location_coordinates_type, :language_text, :language_code, 
                             :publisher, :type_of_resource, :description, :genre, :mime_type, :digital_origin, :identifier, :record_creation_date, 
                             :record_change_date, :resource_status, :additional_notes ], unique: true
  # Non-unique fields
  delegate_to :descMetadata, [:related_web_url, :see_also, :extent, :rights]

  delegate_to :descMetadata, [:subject_topic]

  # People
  delegate_to :descMetadata, [:person_name, :person_role_text]

  # Standard validations for the object fields
  validates :title, presence: true
  validates :genre, presence: true
  validates :subject_topic, array: { :length => { :minimum => 2 } }
  validates :person_name, array: { :length => { :minimum => 5 } }
  validates :person_role_text, array: { :length => { :minimum => 3 } }
  validates :language_code, presence: true
  validates :language_text, presence: true 

  # Overridden so that we can store a cmodel and "complex Object"
  def assert_content_model
    g = Genre.find(self.genre)
    add_relationship(:has_model, "info:fedora/#{g.c_model}")
    add_relationship(:has_model, "info:fedora/hydra-cModel:compoundContent")
    add_relationship(:has_model, "info:fedora/hydra-cModel:commonMetadata")    
  end

  # to_solr overridden to add object_type facet field to document
  def to_solr(solr_doc = {})
    super(solr_doc)
    solr_doc.merge!("object_type_sim" => self.genre)
    solr_doc
  end

end
