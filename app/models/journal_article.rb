# app/models/journal_article.rb
# Fedora object for the Journal Article content type
class JournalArticle < ActiveFedora::Base
  include Hydra::ModelMethods
  include Hyhull::ModelMethods
  include Hyhull::GenericContentBehaviour
  include Hyhull::ContentMetadataBehaviour
  include Hyhull::ResourceWorkflowBehaviour
  include Hyhull::Validators
  include Hyhull::FullTextIndexableBehaviour 

  # Extra validations for the resource_state state changes
  JournalArticle.state_machine :resource_state do   
    state :hidden, :deleted do
      validates :resource_status, presence: true
    end

    state :qa, :published do
      validates :title, presence: true
    end

  end

  has_metadata name: "descMetadata", label: "MODS metadata", type: Datastream::ModsJournalArticle
  has_metadata name: "rightsMetadata", label: "Rights metadata" , type: Hydra::Datastream::RightsMetadata

  # Attributes to respective datastream
  # Multiple false
  has_attributes :title, datastream: :descMetadata, at: [:mods,:title_info, :main_title], multiple: false
  has_attributes :publisher, datastream: :descMetadata, at: [:mods, :origin_info, :publisher], multiple: false

  has_attributes :abstract, :rights, :language_text, :language_code, :date_issued,
                  :peer_reviewed, :journal_title, :journal_publisher, :journal_publication_date, :journal_print_issn,
                  :journal_electronic_issn, :journal_article_doi, :journal_volume, :journal_issue,  :journal_start_page,
                  :journal_end_page, :journal_article_restriction, :type_of_resource, :genre, :mime_type, :digital_origin, 
                  :identifier, :primary_display_url, :raw_object_url, :extent, :record_creation_date, :record_change_date, :resource_status,
                  datastream: :descMetadata, multiple: false

  # Non-unique fields
  # Subjects
  has_attributes :subject_topic, datastream: :descMetadata, multiple: true
  # People
  has_attributes :person_name, :person_role_text, datastream: :descMetadata, multiple: true
 
  # Static Relator terms 
  delegate :person_role_terms, to: Datastream::ModsJournalArticle, multiple: false

  # Standard validations for the object fields
  validates :title, presence: true
  validates :person_name, array: { :length => { :minimum => 5 } }
  validates :person_role_text, array: { :length => { :minimum => 3 } } 
  validates :subject_topic, array: { :length => { :minimum => 2 } }
  validates :publisher, presence: true

  # Overridden so that we can store a cmodel and "complex Object"
  def assert_content_model
    add_relationship(:has_model, "info:fedora/hydra-cModel:compoundContent")
    add_relationship(:has_model, "info:fedora/hydra-cModel:commonMetadata")
    super
  end

  # Overide the attributes method to enable the calling of custom methods
  def attributes=(properties)
    super(properties)
    self.descMetadata.add_names(properties["person_name"], properties["person_role_text"], "person") unless properties["person_name"].nil? or properties["person_role_text"].nil?
  end

  # to_solr overridden to add object_type facet field to document and to add title/publisher fields that are not handled in ModsJounalArticle
  def to_solr(solr_doc = {})
    super(solr_doc)
    solr_doc.merge!("object_type_sim" => "Journal article", "title_tesim" => self.title, "publisher_ssm" => self.publisher)
    solr_doc
  end

end

