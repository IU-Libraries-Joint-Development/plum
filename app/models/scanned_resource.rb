# Generated via
#  `rails generate curation_concerns:work ScannedResource`
class ScannedResource < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include ::CurationConcerns::BasicMetadata
  include ::CommonMetadata
  include ::NoidBehaviors

  contains :logical_order, class_name: "LogicalOrderBase"

  def to_solr(solr_doc = {})
    super.tap do |doc|
      doc[ActiveFedora::SolrQueryBuilder.solr_name("ordered_by", :symbol)] ||= []
      doc[ActiveFedora::SolrQueryBuilder.solr_name("ordered_by", :symbol)] += send(:ordered_by_ids)
      doc[ActiveFedora::SolrQueryBuilder.solr_name("logical_order", :symbol)] = [logical_order.order.to_json]
      doc[ActiveFedora::SolrQueryBuilder.solr_name("logical_order_headings", :stored_searchable)] = logical_order.object.each_section.map(&:label)
      doc[ActiveFedora::SolrQueryBuilder.solr_name("collection", :facetable)] = in_collections.map(&:title)
    end
  end

  def pending_uploads
    PendingUpload.where(curation_concern_id: id)
  end
end
