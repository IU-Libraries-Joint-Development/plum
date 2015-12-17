class ManifestBuilder
  class ManifestPath
    attr_reader :record, :ssl
    def initialize(record, ssl: false)
      @record = record
      @ssl = ssl
    end

    def to_s
      helper.polymorphic_url([:manifest, record], protocol: protocol)
    end

    private

      def helper
        @helper ||= RouteHelper.new
      end

      class RouteHelper
        include Rails.application.routes.url_helpers
        include ActionDispatch::Routing::PolymorphicRoutes
      end

      def ssl?
        @ssl == true
      end

      def protocol
        if ssl?
          :https
        else
          :http
        end
      end
  end
end
