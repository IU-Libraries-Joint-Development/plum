class SearchController < ApplicationController
  def index
    render 'search/search.html.erb'
  end

  def search # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    search_term = params[:q]
    @parent_id = params[:id]
    @parent_path = find_parent_path(@parent_id)
    @response =
      ActiveFedora::SolrService.query("full_text_tesim:(#{search_term})",
                                      fq: "ordered_by_ssim:#{params[:id]}")

    search_terms = search_term.scan(/\w+/)
    @docs = @response.map do |doc|
      doc_text = doc['full_text_tesim'][0]
      hit_number = Array.new
      search_terms.each do |term|
        hit_number << doc_text.scan(/\w+/).count { |t| t.casecmp(term).zero? }
      end
      doc[:hit_number] = hit_number
      doc[:word] = search_terms
      doc
    end

    @pages_json = {}
    @docs.map do |doc|
      json_file =
        PairtreeDerivativePath.derivative_path_for_reference(doc['id'],
                                                             "json")
      next unless File.exist?(json_file)
      json = File.read json_file
      page_json = JSON.parse(json)
      @pages_json[doc['id']] = page_json
    end

    # We keep track of how many times a particular word has had a hit so that
    # we pick the correct @pages_json word boundary. This compensates for how
    # there could be more than one hit in a snippet.
    @hits_used = {}

    request.format = :json
    respond_to :json
  end

  private

    def find_parent_path(id)
      response = ActiveFedora::SolrService.query("id:#{id}")
      base_url = "#{request.protocol}#{request.host_with_port}" \
        "#{config.relative_url_root}"
      base_url.chop! if base_url.end_with? '/'
      "#{base_url}/concern/" \
      "#{response[0]['has_model_ssim'][0].to_s.underscore}s/#{id}"
    end
end
