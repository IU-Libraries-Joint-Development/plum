module CollectionIndexing
  extend ActiveSupport::Concern
  def to_solr(solr_doc = {})
    super.tap do |doc|
      in_collections.each do |col|
        doc[ActiveFedora::SolrQueryBuilder.solr_name("collection", :facetable)] = col.title
        doc[ActiveFedora::SolrQueryBuilder.solr_name("collection_slug", :facetable)] = col.exhibit_id
      end
    end
  end

  def collection_ids
    if persisted?
      in_collections.map(&:id)
    else
      []
    end
  end
end
