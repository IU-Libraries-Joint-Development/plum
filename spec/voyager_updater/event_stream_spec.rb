require 'rails_helper'

RSpec.describe VoyagerUpdater::EventStream,
               vcr: { cassette_name: 'voyager_dump' } do
  let(:event_stream) { described_class.new(url) }
  let(:url) { "https://bibdata.princeton.edu/events.json" }

  describe "#events" do
    it "is a bunch of Events" do
      expect(event_stream.events.map(&:class).uniq).to eq [VoyagerUpdater::Event]
      expect(event_stream.events.length).to eq 3
    end
  end

  describe "#process!" do
    skip "updates all changed records and fires events" do
      s = FactoryGirl.create(:scanned_resource,
                             source_metadata_identifier: "359850")
      manifest_event_generator = instance_double(ManifestEventGenerator)
      allow(ManifestEventGenerator).to receive(:new) \
        .and_return(manifest_event_generator)
      allow(manifest_event_generator).to receive(:record_updated)
      event_stream.process!

      expect(s.reload.title).to eq ["Coda"]
      expect(manifest_event_generator).to have_received(:record_updated).with(s)
    end

    it "logs errors" do
      logger = spy('logger')
      allow(Rails).to receive(:logger).and_return(logger)
      s = FactoryGirl.create(:scanned_resource,
                             source_metadata_identifier: "359850")
      allow(ManifestEventGenerator).to receive(:new).and_return(nil)
      event_stream.process!

      expect(logger).to have_received(:info) \
        .with("Processing updates for IDs: #{s.id}")
      expect(logger).to have_received(:info) \
        .with("Unable to process changed Voyager record #{s.id}")
    end
  end
end
