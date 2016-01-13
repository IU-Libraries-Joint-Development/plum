class AllCollectionsPresenter < CollectionShowPresenter
  def initialize(current_ability = nil)
    @current_ability = current_ability
  end

  def title
    "Plum Collections"
  end

  def description
    "All collections which are a part of Plum."
  end

  def creator
    nil
  end

  def file_presenters
    @file_presenters ||= super.select do |presenter|
      if presenter.current_ability
        presenter.current_ability.can?(:read, presenter.solr_document)
      else
        true
      end
    end
  end

  private

    def current_ability
      @current_ability ||= nil
    end

    def ordered_ids
      ActiveFedora::SolrService.query("active_fedora_model_ssi:Collection", rows: 10_000, fl: "id").map { |x| x["id"] }
    end
end
