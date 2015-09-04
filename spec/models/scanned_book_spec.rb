# Generated via
#  `rails generate worthwhile:work ScannedBook`
require 'rails_helper'

describe ScannedBook do
  let(:scanned_book)  { FactoryGirl.build(:scanned_book, source_metadata_identifier: '12345', access_policy: 'Policy', use_and_reproduction: 'Statement') }
  let(:reloaded)      { described_class.find(scanned_book.id) }
  subject { scanned_book }

  describe 'has note fields' do
    [:portion_note, :description].each do |note_type|
      it "should let me set a #{note_type}" do
        note = 'This is note text'
        subject.send("#{note_type}=", note)
        expect { subject.save }.to_not raise_error
        expect(reloaded.send(note_type)).to eq note
      end
    end
  end

  describe 'has source metadata id' do
    it 'allows setting of metadata id' do
      id = '12345'
      subject.source_metadata_identifier = id
      expect { subject.save }.to_not raise_error
      expect(reloaded.source_metadata_identifier).to eq id
    end

    it 'validates that metadata id is set' do
      subject.source_metadata_identifier = nil
      expect(subject.valid?).to be_falsey
    end
  end

  describe 'has policy fields' do
    # TODO: Set by policy key and test by value
    [:access_policy, :use_and_reproduction].each do |policy_type|
      it "should let me set a #{policy_type}" do
        policy = 'This is a policy'
        subject.send("#{policy_type}=", policy)
        expect { subject.save }.to_not raise_error
        expect(reloaded.send(policy_type)).to eq policy
      end

      it "should require me to set a #{policy_type}" do
        subject.send("#{policy_type}=", nil)
        expect(subject.valid?).to be_falsey
      end
    end
  end

  describe 'With a Pulfa ID', vcr: { cassette_name: 'pulfa' } do
    before do
      subject.source_metadata_identifier = 'AC123_c00004'
    end

    it 'Extracts Pulfa Metadata and full source' do
      subject.apply_external_metadata
      expect(subject.title.first).to eq('Series 1: University Librarian Records - Subseries 1A, Frederic Vinton - Correspondence')
      expect(subject.creator.first).to eq('Princeton University. Library. Dept. of Rare Books and Special Collections')
      expect(subject.publisher.first).to eq('Princeton University. Library. Dept. of Rare Books and Special Collections')
      expect(subject.date_created.first).to eq('1734-2012')
      expect(subject.source_metadata).to eq(fixture('pulfa-AC123_c00004.xml').read)
    end

    # FIXME: Save currently raises a worthwhile dependency error for
    # Curate::DateFormatter
    it 'Saves a record with extacted ead metadata' do
      subject.apply_external_metadata
      subject.save
      expect { subject.save }.to_not raise_error
      expect(subject.id).to be_truthy
    end
  end

  describe 'With a Voyager ID', vcr: { cassette_name: "bibdata"}do
    before do
      subject.source_metadata_identifier = '2028405'
    end

    it 'Extracts Voyager Metadata' do
      subject.apply_external_metadata
      expect(subject.title).to eq(['The Giant Bible of Mainz; 500th anniversary, April fourth, fourteen fifty-two, April fourth, nineteen fifty-two.'])
      expect(subject.creator).to eq(['Miner, Dorothy Eugenia.'])
      expect(subject.date_created).to eq(['1952'])
      expect(subject.publisher).to eq(['Fake Publisher'])
      expect(subject.source_metadata).to eq(fixture('voyager-2028405.xml').read)
    end

    it 'Saves a record with extacted Voyager metadata' do
      subject.apply_external_metadata
      subject.save
      expect { subject.save }.to_not raise_error
      expect(subject.id).to be_truthy
    end
  end

  describe 'gets a noid' do
    it 'that conforms to a valid pattern' do
      expect { subject.save }.to_not raise_error
      noid_service = ActiveFedora::Noid::Service.new
      expect(noid_service.valid? subject.id).to be_truthy
    end
  end
end
