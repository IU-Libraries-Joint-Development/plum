# A work which has metadata and may have one or more ScannedResources members.
class MultiVolumeWork < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include ::CurationConcerns::BasicMetadata
  include ::CommonMetadata
  include ::StructuralMetadata
  include ::HasPendingUploads
  include ::CollectionIndexing
  include ExtraLockable
  self.valid_child_concerns = [ScannedResource]
end
