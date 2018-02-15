class RightsStatementRenderer <
    CurationConcerns::Renderers::RightsAttributeRenderer
  def initialize(rights_statement, rights_note, options = {})
    super(:rights, rights_statement, options)
    @rights_note = rights_note if
      !rights_note.nil? && RightsStatementService.notable?(rights_statement)
    @rights_note ||= []
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Rails/OutputSafety
  def render
    markup = ''

    return markup if values.blank? && !options[:include_empty]
    markup << %(<tr><th>#{label}</th>\n<td><ul class='tabular'>)
    attributes = microdata_object_attributes(field) \
                 .merge(class: "attribute #{field}")
    Array(values).each do |value|
      markup << "<li#{html_attributes(attributes)}>" \
      "#{attribute_value_to_html(value.to_s)}</li>"
    end
    markup << %(</ul>)
    markup << simple_format(RightsStatementService.definition(values.first))
    @rights_note.each do |note|
      markup << %(<p>#{note}</p>) if note.present?
    end
    markup << simple_format(I18n.t('rights.boilerplate'))
    markup << %(</td></tr>)
    markup.html_safe
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Rails/OutputSafety
end
