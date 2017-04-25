module CurationConcerns
  class MultiVolumeWorkForm < ::CurationConcerns::CurationConcernsForm
    self.model_class = ::MultiVolumeWork
    self.terms += [:viewing_direction, :viewing_hint, :sort_title, :published, :physical_description, :series, :publication_place, :date_published, :lccn_call_number, :local_call_number, :copyright_holder, :responsibility_note]

    # Kludge override of Work version, to get thumbnails to work correctly
    # @return [Hash] All volumes, volume.to_s is the key, volume.thumbnail_id is the value
    def select_files
      Hash[scanned_resource_presenters.map { |volume| [volume.to_s, volume.thumbnail_id] }]
    end

    private

      # @return [Array<ScannedResourceShowPresenter>] presenters for the member resources
      def scanned_resource_presenters
        @scanned_resources ||=
          PresenterFactory.build_presenters(model.member_ids, ScannedResourceShowPresenter, current_ability)
      end
  end
end
