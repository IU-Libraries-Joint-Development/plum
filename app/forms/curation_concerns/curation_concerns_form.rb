module CurationConcerns
  class CurationConcernsForm < CurationConcerns::Forms::WorkForm
    self.terms += [:access_policy, :use_and_reproduction, :source_metadata_identifier, :portion_note, :description, :state, :workflow_note]

    def self.multiple?(field)
      if field.to_sym == :description
        false
      else
        super
      end
    end
  end
end
