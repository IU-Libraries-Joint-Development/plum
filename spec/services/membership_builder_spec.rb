require 'rails_helper'

RSpec.describe MembershipBuilder do
  let(:builder) { described_class.new(scanned_resource, members) }

  let(:scanned_resource) { FactoryGirl.create(:scanned_resource) }
  let(:members) {
    [
      FactoryGirl.create(:file_set),
      FactoryGirl.create(:file_set),
      FactoryGirl.create(:file_set)
    ]
  }
  let(:appended) {
    [
      FactoryGirl.create(:file_set),
      FactoryGirl.create(:file_set)
    ]
  }
  let(:reloaded) { scanned_resource.reload }

  describe "#attach_files_to_work" do
    it "apppends file_sets to a work" do
      builder.attach_files_to_work
      expect(members.first.to_solr["ordered_by_ssim"]) \
        .to eq [scanned_resource.id]
      expect(reloaded.ordered_member_ids.length).to eq 3
      described_class.new(reloaded, appended).attach_files_to_work
      expect(members.last.to_solr["ordered_by_ssim"]) \
        .to eq [scanned_resource.id]
      expect(reloaded.ordered_member_ids.length).to eq 5
    end
    it "assigns first member as representative and thumbnail" do
      builder.attach_files_to_work
      # Attaching more should not change the initial assignment
      described_class.new(reloaded, appended).attach_files_to_work
      expect(reloaded.thumbnail.id).to eq members.first.id
      expect(reloaded.representative.id).to eq members.first.id
    end
  end
end
