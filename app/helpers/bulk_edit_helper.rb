module BulkEditHelper
  def bulk_edit_page_header
    h = content_tag(:h1, t('bulk_edit.header'))
    h += bulk_edit_breadcrumb
    h.html_safe
  end

  def bulk_edit_breadcrumb
    content_tag(:ul, class: 'breadcrumb') do
      bulk_edit_parent_work
    end
  end

  def bulk_edit_parent_work
    return '' unless @presenter
    link = content_tag(:a, @presenter.title,
                       title: @presenter.id,
                       href: bulk_edit_parent_path)
    content_tag(:li, ('Back to ' + link).html_safe)
  end

  def bulk_edit_parent_path
    local_helper.polymorphic_path(@presenter)
  end

  private

    def local_helper
      @local_helper ||= ManifestBuilder::ManifestHelper.new
    end
end
