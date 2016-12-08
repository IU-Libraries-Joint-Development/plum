require 'vocab/pul_terms'

# Generated by curation_concerns:models:install
class FileSet < ActiveFedora::Base
  include ::CurationConcerns::FileSetBehavior
  Hydra::Derivatives.output_file_service = PersistPairtreeDerivatives

  property :replaces, predicate: ::RDF::Vocab::DC.replaces, multiple: false
  # override inherited identifier to disallow multiple
  property :identifier, predicate: ::RDF::Vocab::DC.identifier, multiple: false
  property :source_metadata_identifier, predicate: ::PULTerms.metadata_id, multiple: false do |index|
    index.as :stored_searchable, :symbol
  end

  apply_schema IIIFPageSchema, ActiveFedora::SchemaIndexingStrategy.new(
    ActiveFedora::Indexers::GlobalIndexer.new([:stored_searchable, :symbol])
  )

  before_save :normalize_identifiers
  after_save :touch_parent_works

  validates_with ViewingHintValidator

  def self.image_mime_types
    []
  end

  def iiif_path
    IIIFPath.new(id).to_s
  end

  def create_derivatives(filename)
    case
    when mime_type.include?('image/tiff'), mime_type.include?('external')
      Hydra::Derivatives::Jpeg2kImageDerivatives.create(
        filename,
        outputs: [
          label: 'intermediate_file',
          service: {
            datastream: 'intermediate_file',
            recipe: :default
          },
          url: derivative_url('intermediate_file')
        ]
      )
      RunOCRJob.perform_later(id) if Plum.config[:store_original_files]
    when mime_type.include?('image/jp2')
      dst = derivative_path('intermediate_file')
      FileUtils.mkdir_p(File.dirname(dst))
      FileUtils.cp(filename, dst)
    when 'text/plain'
      if filename.end_with?("fulltext.txt")
        dst = derivative_path('ocr')
        FileUtils.mkdir_p(File.dirname(dst))
        FileUtils.cp(filename, dst)
      end
    end
    super
  end

  def to_solr(solr_doc = {})
    super.tap do |doc|
      doc["full_text_tesim"] = ocr_text if ocr_text.present?
      doc["ordered_by_ssim"] = ordered_by.map(&:id).to_a
    end
  end

  def ocr_document
    return unless persisted? && File.exist?(ocr_file.gsub("file:", ""))
    @ocr_document ||=
      begin
        file = File.open(ocr_file.gsub("file:", ""))
        HOCRDocument.new(file)
      end
  end

  private

    def touch_parent_works
      TouchParentJob.perform_later(self)
    end

    def ocr_file
      derivative_url('ocr')
    end

    def ocr_text
      ocr_document.try(:text).try(:strip)
    end

    # The destination_name parameter has to match up with the file parameter
    # passed to the DownloadsController
    def derivative_url(destination_name)
      path = PairtreeDerivativePath.derivative_path_for_reference(self, destination_name)
      URI("file://#{path}").to_s
    end

    def derivative_path(destination_name)
      PairtreeDerivativePath.derivative_path_for_reference(self, destination_name).to_s
    end

    def normalize_identifiers
      self.source_metadata_identifier = label.gsub(/\.\w{3,4}$/, '').upcase unless label.nil?
    end
end
