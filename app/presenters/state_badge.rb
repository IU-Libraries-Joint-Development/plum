class StateBadge
  include ActionView::Helpers::TagHelper

  def initialize(solr_document)
    @solr_document = solr_document
  end

  def render
    content_tag(:span, link_title, title: link_title, class: "label #{dom_label_class}")
  end

  private

    def dom_label_class
      if complete?
        'label-success'
      elsif review?
        'label-info'
      else
        'label-warning'
      end
    end

    def link_title
      if complete?
        'Complete'
      elsif review?
        'Review'
      else
        'Pending'
      end
    end

    def complete?
      @solr_document.state == 'complete'
    end

    def review?
      @solr_document.state == 'review'
    end
end
