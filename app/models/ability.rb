class Ability
  include Hydra::Ability
  include CurationConcerns::Ability

  # Define any customized permissions here.
  def custom_permissions
    alias_action :show, :manifest, to: :read
    alias_action :edit, to: :modify
    # alias_action :color_pdf, :pdf, :edit, to: :modify
    roles.each do |role|
      send "#{role}_permissions" if current_user.send "#{role}?"
    end
  end

  # Abilities that should only be granted to admin users
  def admin_permissions
    can %i[manage], :all
  end

  # Abilities that should be granted to technicians
  def image_editor_permissions
    can %i[read create modify update publish], curation_concerns
    can %i[file_manager save_structure], ScannedResource
    can %i[file_manager save_structure], MultiVolumeWork
    can %i[create read edit update publish download], FileSet
    can %i[create read edit update publish], Collection

    # do not allow completing resources
    cannot %i[complete], curation_concerns

    # only allow deleting for own objects, without ARKs
    can %i[destroy], FileSet, depositor: current_user.uid
    can %i[destroy], curation_concerns, depositor: current_user.uid
    cannot %i[destroy], curation_concerns do |obj|
      !obj.identifier.nil?
    end
  end

  def editor_permissions
    can %i[read modify update], curation_concerns
    can %i[file_manager save_structure], ScannedResource
    can %i[file_manager save_structure], MultiVolumeWork
    can %i[read edit update], FileSet
    can %i[read edit update], Collection

    # do not allow completing resources
    cannot [:complete], curation_concerns

    curation_concern_read_permissions
  end

  def fulfiller_permissions
    can %i[read], curation_concerns
    can %i[read download], FileSet
    can %i[read], Collection
    curation_concern_read_permissions
  end

  def curator_permissions
    can %i[read], curation_concerns
    can %i[read], FileSet
    can %i[read], Collection

    # do not allow viewing pending resources
    curation_concern_read_permissions
  end

  # Abilities that should be granted to patrons in an authorized group
  # Ability to read authenticated visibility items is handled by #user_groups
  def music_patron_permissions
    curation_concern_read_permissions
    can [:flag], curation_concerns
  end

  # Abilities that should be granted to patrons not in an authorized group
  def campus_patron_permissions
    anonymous_permissions
  end

  def anonymous_permissions
    # do not allow viewing incomplete resources
    curation_concern_read_permissions
  end

  def curation_concern_read_permissions
    cannot [:read], curation_concerns do |curation_concern|
      !readable_concern?(curation_concern)
    end
    # can :pdf, (curation_concerns + [ScannedResourceShowPresenter]) do |curation_concern|
    #   ["color", "gray"].include?(Array(curation_concern.pdf_type).first)
    # end
    # can :color_pdf, (curation_concerns + [ScannedResourceShowPresenter]) do |curation_concern|
    #   curation_concern.pdf_type == ["color"]
    # end
  end

  def readable_concern?(curation_concern)
    !unreadable_states.include?(curation_concern.state)
  end

  def unreadable_states
    if current_user.curator?
      %w[pending]
    elsif universal_reader?
      []
    else
      %w[pending metadata_review final_review takedown]
    end
  end

  def user_groups
    return @user_groups if @user_groups

    @user_groups = default_user_groups
    @user_groups |= current_user.groups if current_user.respond_to? :groups
    if Plum.config[:authorized_ldap_groups].blank?
      @user_groups |= ['registered'] unless current_user.new_record?
    elsif current_user.music_patron?
      @user_groups |= ['registered']
    end
    @user_groups
  end

  private

    def universal_reader?
      current_user.curator? || current_user.image_editor? || current_user.fulfiller? || current_user.editor? || current_user.admin?
    end

    def curation_concerns
      CurationConcerns.config.curation_concerns
    end

    def roles
      ['anonymous', 'music_patron', 'campus_patron', 'curator', 'fulfiller', 'editor', 'image_editor', 'admin']
    end
end
