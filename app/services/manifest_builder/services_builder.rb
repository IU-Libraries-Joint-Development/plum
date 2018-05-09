class ManifestBuilder
  class ServicesBuilder
    include Rails.application.routes.url_helpers

    attr_reader :record

    def initialize(record)
      @record = record
      # @searchable = record.full_text_searchable[0] unless record.full_text_searchable.nil?
    end

    def apply(manifest)
      return if
        record.class == AllCollectionsPresenter ||
        record.class == CollectionShowPresenter ||
        searchable? == 'disabled'
      search_service_array = search_service
      ocr_service_array = ocr_service
      manifest["service"] = [search_service_array, ocr_service_array]
    end

    private

      def searchable?
        record.full_text_searchable[0] unless record.full_text_searchable.nil?
      end

      def search_service
        {
          "@context"  => "http://iiif.io/api/search/0/context.json",
          "@id"       => "#{root_url}search/#{record.id}",
          "profile"   => "http://iiif.io/api/search/0/search",
          "label"     => "Search within item."
        }
      end

      def ocr_service
        {
          "@context"  => "http://www.w3.org/ns/anno.jsonld",
          "@id"       => "#{root_url}ocr/#{record.id}",
          "profile"   => "http://4science.it/api/ocr/0/annotationCollection",
          "label"     => "OCR"
        }
      end
  end
end
