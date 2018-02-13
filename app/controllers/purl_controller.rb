# new class for imago to handle purl redirection
class PurlController < ApplicationController
  def default # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    begin
      set_object
      realid = @solr_hit.id
      url = "#{request.protocol}#{request.host_with_port}" \
        "#{config.relative_url_root}/concern/#{@subfolder}/#{realid}"
    rescue
      url = Plum.config['purl_redirect_url'] % params[:id]
    end
    respond_to do |f|
      f.html { redirect_to url }
      f.json { render json: { url: url }.to_json }
    end
  end

  private

    OBJECT_LOOKUPS = {
      FileSet => /^\w{3}\d{4}-\d{1}-\d{4}$/,
      MultiVolumeWork => /^\w{3}\d{4}$/,
      ScannedResource => /^\w{3}\d{4}$/
    }.freeze

    def set_object
      OBJECT_LOOKUPS.each do |klass, match_pattern|
        if params[:id].match match_pattern
          @solr_hit = klass.search_with_conditions(
            { source_metadata_identifier_tesim: params[:id] }, rows: 1
          ).first
          @subfolder = klass.to_s.pluralize.underscore
        end
        break if @solr_hit
      end
    end
end
