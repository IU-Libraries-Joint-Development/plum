require 'rails_helper'

RSpec.describe ExhibitIdValidator do
  let(:validator) { described_class.new }

  describe "#validate" do
    let(:errors) { instance_double("Errors") }
    let(:solr_response) {
      {
        "facet_counts": {
          "facet_fields": {
            "exhibit_id_tesim": ['slug1', 1]
          }.stringify_keys
        }.stringify_keys
      }.stringify_keys
    }

    # rubocop:disable RSpec/ExpectInHook
    before do
      # rubocop:disable RSpec/MessageSpies
      expect(ActiveFedora::SolrService).to receive(:get) \
        .and_return(solr_response)
      # rubocop:enable RSpec/MessageSpies
      allow(errors).to receive(:add)
    end
    # rubocop:enable RSpec/ExpectInHook

    context "when the exhibit id unique" do
      it "does not add errors" do
        record = build_record("slug2")
        validator.validate(record)

        expect(errors).not_to have_received(:add)
      end
    end

    context "when the exhibit id already exists" do
      it "adds errors" do
        record = build_record("slug1")
        validator.validate(record)

        expect(errors).to have_received(:add) \
          .with(:exhibit_id, :exclusion, value: "slug1")
      end
    end
  end

  def build_record(exhibit_id) # rubocop:disable Metrics/AbcSize
    record = object_double Collection.new
    allow(record).to receive(:errors).and_return(errors)
    allow(record).to receive(:exhibit_id).and_return(exhibit_id)
    allow(record).to receive(:exhibit_id_changed?).and_return(true)
    allow(record).to receive(:read_attribute_for_validation) \
      .with(:exhibit_id).and_return(record.exhibit_id)
    record
  end
end
