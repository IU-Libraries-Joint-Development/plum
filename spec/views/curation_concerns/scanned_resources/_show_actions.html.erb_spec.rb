require 'rails_helper'

RSpec.describe "curation_concerns/scanned_resources/_show_actions.html.erb" do
  let(:resource) do
    r = FactoryGirl.build(:scanned_resource)
    allow(r).to receive(:id).and_return("test")
    r
  end
  let(:solr_document) { SolrDocument.new(resource.to_solr) }
  let(:presenter) { ScannedResourceShowPresenter.new(solr_document, nil) }
  let(:editor) { true }
  let(:collector) { true }
  before do
    assign(:presenter, presenter)
    render partial: "curation_concerns/scanned_resources/show_actions", locals: { collector: collector, editor: editor }
  end
  it "renders a reorder link" do
    expect(rendered).to have_link "Reorder", curation_concerns_scanned_resource_reorder_path(id: resource.id)
  end
end
