require 'rails_helper'

RSpec.describe "CatalogController", type: :feature do
  describe "admin user" do
    let(:user) { FactoryGirl.create(:admin) }
    let(:scanned_resource) {
      FactoryGirl.create(:scanned_resource_in_collection,
                         user: user,
                         language: ['English'])
    }

    before do
      sign_in user
      scanned_resource.update_index
    end

    it "Admin users see collection, language, and state facets" do
      visit search_catalog_path q: ""
      expect(page).to have_text "Test title"
      expect(page) \
        .to have_selector("div.blacklight-member_of_collections_ssim",
                          text: "Collection")
      expect(page).to have_selector("div.blacklight-language_sim",
                                    text: "Language")
      expect(page).to have_selector "div.blacklight-state_sim", text: "State"
    end
  end

  describe "image_editor user" do
    let(:user) { FactoryGirl.create(:image_editor) }
    let(:scanned_resource) {
      FactoryGirl.create(:scanned_resource, user: user)
    }

    before do
      sign_in user
      scanned_resource.update_index
    end

    it "CurationConcerns creators see a state facet" do
      visit search_catalog_path q: ""
      expect(page).to have_text "Test title"
      expect(page).to have_selector "div.blacklight-state_sim", text: "State"
    end

    it "CurationConcerns creators see editing links" do
      visit search_catalog_path q: ""
      expect(page).to have_text "Test title"
      expect(page).to have_selector("a.itemedit",
                                    text: "Edit Scanned Resource")
    end
  end

  describe "anonymous user" do
    let(:user) { FactoryGirl.create(:image_editor) }
    let(:scanned_resource) {
      FactoryGirl.create(:scanned_resource, user: user)
    }

    before do
      scanned_resource.update_index
    end

    it "Anonymous users do not see a state facet" do
      visit search_catalog_path q: ""
      expect(page).to have_text "Test title"
      expect(page).not_to have_selector("div.blacklight-state_sim",
                                        text: "State")
    end

    it "Anonymous users see a viewer link" do
      visit search_catalog_path q: ""
      expect(page).to have_text "Test title"
      expect(page).to have_selector "a.itemshow", text: "Open in Viewer"
    end
  end
end
