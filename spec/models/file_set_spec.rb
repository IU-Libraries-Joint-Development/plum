require 'rails_helper'

RSpec.describe FileSet do
  let(:file_set) {
    described_class.new.tap { |x| x.apply_depositor_metadata("bob") }
  }

  describe "metadata" do
    context "singular" do
      {
        'viewing_hint' => ::RDF::Vocab::IIIF.viewingHint,
        'identifier' => ::RDF::Vocab::DC.identifier,
        'source_metadata_identifier' => ::PULTerms.metadata_id,
        'replaces' => ::RDF::Vocab::DC.replaces
      }.each do |attribute, predicate|
        describe "##{attribute}" do
          it "has the right predicate" do
            expect(described_class.properties[attribute].predicate) \
              .to eq predicate
          end
          it "disallows multiple values" do
            expect(described_class.properties[attribute].multiple?) \
              .to eq false
          end
        end
      end
    end
  end

  describe "validations" do
    it "validates with the viewing hint validator" do
      expect(file_set._validators[nil].map(&:class)) \
        .to include ViewingHintValidator
    end
  end

  describe "iiif_path" do
    it "returns the manifest path" do
      allow(file_set).to receive(:id).and_return("1")

      expect(file_set.iiif_path) \
        .to eq "http://192.168.99.100:5004/1-intermediate_file.jp2"
    end
  end

  it "can persist" do
    expect { file_set.save! }.not_to raise_error
  end

  describe "#create_derivatives" do
    let(:path) {
      Pathname.new(PairtreeDerivativePath \
                     .derivative_path_for_reference(file_set,
                                                    'intermediate_file'))
    }
    let(:thumbnail_path) {
      Pathname.new(PairtreeDerivativePath \
                     .derivative_path_for_reference(file_set, 'thumbnail'))
    }
    let(:ocr_path) {
      Pathname.new(PairtreeDerivativePath \
                     .derivative_path_for_reference(file_set, 'ocr'))
    }

    it "doesn't create a thumbnail" do
      allow_any_instance_of(described_class) \
        .to receive(:warn) # suppress virus check warnings
      file = File.open(Rails.root.join("spec", "fixtures", "files",
                                       "color.tif"))
      Hydra::Works::UploadFileToFileSet.call(file_set, file)
      file_set.create_derivatives(file.path)

      expect(thumbnail_path).not_to exist
    end
    it "creates a JP2" do
      allow_any_instance_of(described_class)\
        .to receive(:warn) # suppress virus check warnings
      file = File.open(Rails.root.join("spec", "fixtures", "files",
                                       "color.tif"))
      Hydra::Works::UploadFileToFileSet.call(file_set, file)

      file_set.create_derivatives(file.path)

      expect(path).to exist
    end
    it "copies a JP2" do
      allow_any_instance_of(described_class) \
        .to receive(:warn) # suppress virus check warnings
      file = File.open(Rails.root.join("spec", "fixtures", "files",
                                       "image.jp2"))
      Hydra::Works::UploadFileToFileSet.call(file_set, file)

      file_set.create_derivatives(file.path)

      expect(path).to exist
    end
    it "creates full text, attaches it to the object, and indexes it" do
      allow_any_instance_of(described_class) \
        .to receive(:warn) # suppress virus check warnings
      allow(Hydra::Derivatives::Jpeg2kImageDerivatives) \
        .to receive(:create).and_return(true)
      file = File.open(Rails.root.join("spec", "fixtures", "files",
                                       "page18.tif"))
      Hydra::Works::UploadFileToFileSet.call(file_set, file)
      allow_any_instance_of(HOCRDocument).to receive(:text).and_return("yo")
      allow(Plum.config).to receive(:[]).with(:store_original_files) \
                                        .and_return(true)
      allow(Plum.config).to receive(:[]).with(:create_hocr_files) \
                                        .and_return(true)
      allow(Plum.config).to receive(:[]).with(:index_hocr_files) \
                                        .and_return(true)
      allow(Plum.config).to receive(:[]).with(:create_word_boundaries) \
                                        .and_return(true)

      file_set.create_derivatives(file.path)

      expect(ocr_path).to exist
      expect(file_set.to_solr["full_text_tesim"]).to eq "yo"

      # verify that ocr has been added to the FileSet
      file_set.reload
      expect(file_set.files.size).to eq(2)
      expect(file_set.files.to_a \
               .find { |x| x.mime_type != "image/tiff" } \
               .content) \
        .to include "<div class='ocr_page'"
    end
    it "does not create full text if OCR is disabled in configuration." do
      allow_any_instance_of(described_class) \
        .to receive(:warn) # suppress virus check warnings
      allow(Hydra::Derivatives::Jpeg2kImageDerivatives) \
        .to receive(:create).and_return(true)
      file = File.open(Rails.root.join("spec", "fixtures", "files",
                                       "page18.tif"))
      Hydra::Works::UploadFileToFileSet.call(file_set, file)
      allow_any_instance_of(HOCRDocument).to receive(:text).and_return("yo")
      allow(Plum.config).to receive(:[]).with(:store_original_files) \
                                        .and_return(true)
      allow(Plum.config).to receive(:[]).with(:create_hocr_files) \
                                        .and_return(false)
      allow(Plum.config).to receive(:[]).with(:create_word_boundaries) \
                                        .and_return(false)

      file_set.create_derivatives(file.path)

      expect(ocr_path).not_to exist
    end
    it "creates full text from text file when provided." do
      allow_any_instance_of(described_class) \
        .to receive(:warn) # suppress virus check warnings
      text_file = File.open(Rails.root.join("spec", "fixtures", "files",
                                            "fulltext.txt"))
      Hydra::Works::UploadFileToFileSet.call(file_set, text_file)
      allow(Plum.config).to receive(:[]).with(:store_original_files) \
                                        .and_return(true)
      allow(Plum.config).to receive(:[]).with(:create_hocr_files) \
                                        .and_return(false)
      allow(Plum.config).to receive(:[]).with(:index_hocr_files) \
                                        .and_return(false)
      allow(Plum.config).to receive(:[]).with(:create_word_boundaries) \
                                        .and_return(false)

      file_set.create_derivatives(text_file.path)

      expect(ocr_path.sub(".hocr", ".txt")).to exist
      expect(file_set.to_solr["full_text_tesim"]).to include "OCR text file."
    end

    context "store_original_files is false" do
      it "still creates, stores, and indexes OCR derivatives" do
        allow_any_instance_of(described_class) \
          .to receive(:warn) # suppress virus check warnings
        allow(Hydra::Derivatives::Jpeg2kImageDerivatives) \
          .to receive(:create).and_return(true)
        file = File.open(Rails.root.join("spec", "fixtures", "files",
                                         "page18.tif"))
        Hydra::Works::UploadFileToFileSet.call(file_set, file)

        # Don't store an original to Fedora,
        # make sure derivatives still come from original local file
        allow(Plum.config).to receive(:[]).with(:store_original_files) \
                                          .and_return(false)
        allow(Plum.config).to receive(:[]).with(:create_hocr_files) \
                                          .and_return(true)
        allow(Plum.config).to receive(:[]).with(:index_hocr_files) \
                                          .and_return(true)
        allow(Plum.config).to receive(:[]).with(:create_word_boundaries) \
                                          .and_return(true)
        file_set.create_derivatives(file.path)

        # verify that ocr has been added to the FileSet
        expect(ocr_path).to exist
        file_set.reload
        expect(file_set.files.size).to eq(2)
      end
    end
    after do
      FileUtils.rm_rf(path.parent) if path.exist?
      FileUtils.rm_rf(ocr_path.parent) if ocr_path.exist?
    end
  end
end
