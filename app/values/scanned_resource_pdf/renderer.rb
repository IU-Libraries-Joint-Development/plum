class ScannedResourcePDF
  class Renderer
    attr_reader :scanned_resource_pdf, :path
    delegate :manifest_builder, to: :scanned_resource_pdf
    def initialize(scanned_resource_pdf, path)
      @scanned_resource_pdf = scanned_resource_pdf
      @path = path
    end

    def render
      canvas_downloaders.each_with_index do |downloader, index|
        prawn_document.start_new_page layout: downloader.layout if index > 0
        page_size = [Canvas::LETTER_WIDTH, Canvas::LETTER_HEIGHT]
        page_size.reverse! unless downloader.portrait?
        prawn_document.image downloader.download, width: downloader.width, height: downloader.height, fit: page_size
      end
      prawn_document.render_file(path)
      File.open(path)
    end

    def canvas_images
      @canvas_images ||= manifest_builder.canvases.flat_map(&:images).map do |x|
        Canvas.new(x)
      end
    end

    private

      def canvas_downloaders
        @canvas_images ||= canvas_images.map do |image|
          CanvasDownloader.new(image)
        end
      end

      def prawn_document
        @prawn_document ||= Prawn::Document.new(prawn_options)
      end

      def prawn_options
        default_options = { margin: 0 }
        if canvas_downloaders.first
          default_options[:page_layout] = canvas_downloaders.first.layout
        end
        default_options
      end
  end
end
