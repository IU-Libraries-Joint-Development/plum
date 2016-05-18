class RightsStatementRenderer < CurationConcerns::Renderers::AttributeRenderer
  def initialize(rights_statement, rights_note, options = {})
    super(:rights, rights_statement, options)
    if !rights_note.nil? && RightsStatementService.notable?(rights_statement)
      @rights_note = rights_note
    else
      @rights_note = []
    end
  end

  def render
    markup = ''

    return markup if !values.present? && !options[:include_empty]
    markup << %(<tr><th>#{label}</th>\n<td><ul class='tabular'>)
    attributes = microdata_object_attributes(field).merge(class: "attribute #{field}")
    Array(values).each do |value|
      markup << "<li#{html_attributes(attributes)}>#{attribute_value_to_html(value.to_s)}</li>"
    end
    markup << %(</ul>)
    markup << simple_format(RightsStatementService.definition(values.first))
    @rights_note.each do |note|
      markup << %(<p>#{note}</p>) unless note.blank?
    end
    markup << simple_format(I18n.t('rights.boilerplate'))
    markup << %(</td></tr>)
    markup.html_safe
  end
end
