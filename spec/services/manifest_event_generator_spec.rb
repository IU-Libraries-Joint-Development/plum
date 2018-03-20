require 'rails_helper'

RSpec.describe ManifestEventGenerator do
  context "Message queue is disabled" do
    let(:generator) { described_class.new(rabbit_connection) }

    let(:rabbit_connection) {
      instance_double(MessagingClient, publish: true, enabled?: false)
    }
    let(:record) { FactoryGirl.build(:scanned_resource) }

    describe "#record_created" do
      it "does not publish" do
        expect(generator.record_created(record)).to eq(false)
        expect(rabbit_connection).not_to have_received(:publish)
      end
    end
    describe "#record_deleted" do
      it "does not publish" do
        expect(generator.record_deleted(record)).to eq(false)
        expect(rabbit_connection).not_to have_received(:publish)
      end
    end
    describe "#record_updated" do
      it "does not publish" do
        expect(generator.record_updated(record)).to eq(false)
        expect(rabbit_connection).not_to have_received(:publish)
      end
    end
  end

  context "Message queue is enabled" do
    let(:generator) { described_class.new(rabbit_connection) }

    let(:rabbit_connection) {
      instance_double(MessagingClient, publish: true, enabled?: true)
    }
    let(:record) { FactoryGirl.build(:scanned_resource) }
    let(:collection) { FactoryGirl.create(:collection) }
    let(:record_in_collection) {
      FactoryGirl.build(:scanned_resource,
                        member_of_collections: [collection])
    }

    describe "#record_created" do
      it "publishes a persistent JSON message" do
        record.save
        expected_result = {
          "id" => record.id,
          "event" => "CREATED",
          "manifest_url" =>
          "http://plum.com/concern/scanned_resources/#{record.id}/manifest",
          "collection_slugs" => []
        }

        generator.record_created(record)

        expect(rabbit_connection).to have_received(:publish) \
          .with(expected_result.to_json)
      end
      it "embeds collection memberships" do
        record_in_collection.save!
        expected_result = {
          "id" => record_in_collection.id,
          "event" => "CREATED",
          "manifest_url" => "http://plum.com/concern/scanned_resources/" \
          "#{record_in_collection.id}/manifest",
          "collection_slugs" => [collection.exhibit_id]
        }

        generator.record_created(record_in_collection)

        expect(rabbit_connection).to have_received(:publish) \
          .with(expected_result.to_json)
      end
    end

    describe "#record_deleted" do
      it "publishes a persistent JSON message" do
        record.save
        record.destroy
        expected_result = {
          "id" => record.id,
          "event" => "DELETED",
          "manifest_url" =>
          "http://plum.com/concern/scanned_resources/#{record.id}/manifest"
        }

        generator.record_deleted(record)

        expect(rabbit_connection).to have_received(:publish) \
          .with(expected_result.to_json)
      end
    end

    describe "#record_updated" do
      it "publishes a persistent JSON message with collection memberships" do
        collection = FactoryGirl.create(:collection)
        record.member_of_collections = [collection]
        record.save!
        expected_result = {
          "id" => record.id,
          "event" => "UPDATED",
          "manifest_url" =>
          "http://plum.com/concern/scanned_resources/#{record.id}/manifest",
          "collection_slugs" => [collection.exhibit_id]
        }

        generator.record_updated(record)

        expect(rabbit_connection).to have_received(:publish) \
          .with(expected_result.to_json)
      end
    end
  end
end
