require 'rails_helper'

RSpec.describe 'Collections', type: :feature do
  describe 'an anonymous user is not allowed to create a collection' do
    it 'link to create a collection is not shown' do
      visit root_path
      expect(page).not_to have_link 'Add a Collection'
    end

    it 'attempting to create a collection fails' do
      visit new_collection_path
      expect(page) \
        .to have_selector('div.alert',
                          text: 'You are not authorized to access this page')
    end
  end

  describe 'a logged in user is allowed to create a collection' do
    let(:user) { FactoryGirl.create(:image_editor) }

    before do
      sign_in user
    end

    it 'is allowed to create collections' do
      visit root_path
      expect(page).to have_link 'Add a Collection'

      click_link 'Add a Collection'
      expect(page).to have_selector 'h1', text: 'Create New Collection'

      fill_in 'collection_title', with: 'Test Collection'
      fill_in 'collection_exhibit_id', with: 'slug1'
      click_button 'Create Collection'
      expect(page).to have_selector 'h1', text: 'Test Collection'
      expect(page).to have_selector 'li.exhibit_id', text: 'slug1'
    end
    it 'is edited' do
      c = FactoryGirl.create(:collection, user: user)
      visit collection_path(c)
      click_link 'Edit'

      expect(page).to have_field 'collection_title', with: c.title.first
      fill_in 'collection_title', with: "Alfafa"
      click_button "Update Collection"
      expect(page).to have_selector "h1", text: "Alfafa"
    end
    it 'fails to input exhibit ID' do
      visit root_path
      expect(page).to have_link 'Add a Collection'

      click_link 'Add a Collection'
      expect(page).to have_selector 'h1', text: 'Create New Collection'

      fill_in 'collection_title', with: 'Test Collection'
      click_button 'Create Collection'
      expect(page).to have_selector ".alert"
    end
  end

  describe 'adding resources to collections' do
    let(:collection1) { FactoryGirl.create(:collection, title: ['Col 1']) }
    let(:collection2) { FactoryGirl.create(:collection, title: ['Col 2']) }
    let(:resource) { FactoryGirl.create(:scanned_resource) }
    let(:user) { FactoryGirl.create(:image_editor) }

    before do
      collection1
      collection2
      resource
      sign_in user
    end
    it "works" do
      visit edit_polymorphic_path [resource]
      select 'Col 1', from: 'scanned_resource[member_of_collection_ids][]'
      click_button 'Update Scanned resource'
      expect(page).to have_selector 'a.collection-link', text: 'Col 1'
      expect(page).not_to have_selector 'a.collection-link', text: 'Col 2'

      visit edit_polymorphic_path [resource]
      select 'Col 2', from: 'scanned_resource[member_of_collection_ids][]'
      unselect 'Col 1', from: 'scanned_resource[member_of_collection_ids][]'
      click_button 'Update Scanned resource'
      expect(page).not_to have_selector 'a.collection-link', text: 'Col 1'
      expect(page).to have_selector 'a.collection-link', text: 'Col 2'

      visit edit_polymorphic_path [resource]
      unselect 'Col 2', from: 'scanned_resource[member_of_collection_ids][]'
      click_button 'Update Scanned resource'
      expect(page).not_to have_selector 'a.collection-link', text: 'Col 1'
      expect(page).not_to have_selector 'a.collection-link', text: 'Col 2'
    end
  end
end
