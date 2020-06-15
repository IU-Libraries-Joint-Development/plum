# rubocop:disable Metrics/ClassLength
class CurationConcerns::CurationConcernsController < ApplicationController
  include CurationConcerns::CurationConcernController
  include CurationConcerns::Manifest
  include CurationConcerns::MemberManagement
  include CurationConcerns::LockWarning
  include CurationConcerns::UpdateOCR
  include CurationConcerns::RemoteMetadata

  def curation_concern_name
    curation_concern.class.name.underscore
  end

  def update
    if curation_concern.state != 'complete' &&
       params[curation_concern_name][:state] == 'complete'
      authorize!(:complete, curation_concern,
                 message: 'Unable to mark resource complete')
    end
    super
  end

  def alphabetize_members
    @sorted = curation_concern.members.sort do |x, y|
      x.label.to_s <=> y.label.to_s
    end
    flash[:notice] = "Files have been ordered alphabetically, by filename."
    curation_concern.update_attributes(ordered_members: @sorted)
    redirect_to :back
  end

  def destroy
    messenger.record_deleted(curation_concern)
    super
  end

  def destroy_collection_membership
    curation_concern.destroy_collection_membership
    curation_concern.save!
    flash[:notice] = "All collection membership entries have been destroyed"
    redirect_to :back
  end

  def file_manager
    parent_presenter
    super
  end

  def flag # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    curation_concern.state = 'flagged'
    note = params[curation_concern_name][:workflow_note]
    if note.present?
      curation_concern.workflow_note =
        curation_concern.workflow_note + [note]
    end
    if curation_concern.save
      respond_to do |format|
        format.html do
          redirect_to [main_app, curation_concern],
                      notice: "Resource updated"
        end
        format.json { render json: { state: state } }
      end
    else
      respond_to do |format|
        format.html do
          redirect_to [main_app, curation_concern],
                      alert: "Unable to update resource"
        end
        format.json { render json: { error: "Unable to update resource" } }
      end
    end
  end

  def browse_everything_files # rubocop:disable Metrics/AbcSize
    upload_set_id = ActiveFedora::Noid::Service.new.mint
    CompositePendingUpload.create(selected_files_params, curation_concern.id,
                                  upload_set_id)
    BrowseEverythingIngestJob.perform_later(curation_concern.id,
                                            upload_set_id, current_user,
                                            selected_files_params)
    redirect_to ::ContextualPath.new(curation_concern,
                                     parent_presenter).file_manager
  end

  def after_create_response
    send_record_created
    super
  end

  def send_record_created
    messenger.record_created(curation_concern)
  end

  protected

    def additional_response_formats(wants)
      wants.uv do
        presenter && parent_presenter
        render 'viewer_only.html.erb',
               layout: 'boilerplate',
               content_type: 'text/html'
      end
    end

  private

    def search_builder_class
      ::WorkSearchBuilder
    end

    def messenger
      @messenger ||= ManifestEventGenerator.new(Plum.messaging_client)
    end

    def curation_concern
      @decorated_concern ||=
        begin
          @curation_concern = decorator.new(@curation_concern)
        end
    end

    def decorator
      CompositeDecorator.new(super, NullDecorator)
    end

    def selected_files_params
      @whitelisted_upload_files ||=
        params[:selected_files].delete_if do |_key, value|
          !validate_remote_url(value['url'])
        end
    end

    def whitelisted_ingest_dirs
      CurationConcerns.config.whitelisted_ingest_dirs
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def validate_remote_url(url)
      uri = URI.parse(URI.encode_www_form_component(url))
      if uri.scheme == 'file'
        path = File.absolute_path(URI.decode_www_form_component(uri.path))
        result = whitelisted_ingest_dirs.any? do |dir|
          path.start_with?(dir) && path.length > dir.length
        end
        unless result
          Rails.logger.error "User #{current_user.user_key} attempted to" \
            " ingest file from url #{url}, which doesn't pass validation" \
            " and has been skipped."
        end
        result
      else
        # TODO: It might be a good idea to validate other URLs as well.
        #       The server can probably access URLs the user can't.
        true
      end
    end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
# rubocop:enable Metrics/ClassLength
