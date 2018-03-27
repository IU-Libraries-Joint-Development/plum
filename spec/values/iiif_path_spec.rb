require 'rails_helper'

RSpec.describe IIIFPath do
  let(:iiif_path) { described_class.new("zs5439h") }

  describe "#to_s" do
    it "returns the path to the access copy" do
      expect(iiif_path.to_s) \
        .to eq "http://192.168.99.100:5004" \
      "/zs%2F54%2F39%2Fh-intermediate_file.jp2"
    end
  end
end
