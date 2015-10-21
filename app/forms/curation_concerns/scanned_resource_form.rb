module CurationConcerns
  class ScannedResourceForm < CurationConcerns::Forms::WorkForm
    self.model_class = ::ScannedResource
    self.terms += [:access_policy, :use_and_reproduction, :source_metadata_identifier, :portion_note, :description]

    def self.multiple?(field)
      if field.to_sym == :description
        false
      else
        super
      end
    end
  end
end
