class MembershipBuilder
  include CurationConcerns::Lockable

  attr_reader :work, :members

  def initialize(work, members)
    @work = work
    @members = members
  end

  # Modified from FileSetActor#attach_file_to_work
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def attach_files_to_work
    return if @members.empty?
    acquire_lock_for(work.id) do
      # Ensure we have an up-to-date copy of the members association, so
      # that we append to the end of the list.
      work.reload unless work.new_record?
      members.each do |member|
        work.ordered_members << member
        ActiveFedora.solr.conn.add member.to_solr \
                                         .merge(ordered_by_ssim: [work.id])
      end
      set_representative(work, members.first)
      set_thumbnail(work, members.first)
      work.save!
      messenger.record_updated(work)
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

    def set_representative(work, file_set)
      return unless work.representative_id.blank?
      work.representative = file_set
    end

    def set_thumbnail(work, file_set)
      return unless work.thumbnail_id.blank?
      work.thumbnail = file_set
    end

    def messenger
      @messenger ||= ManifestEventGenerator.new(Plum.messaging_client)
    end
end
