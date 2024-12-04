# frozen_string_literal: true

require_relative '../../../helpers/spec_helper'
require_relative '../../../helpers/vcr_helper'
require_relative '../../../helpers/database_helper'

describe 'FindSongsFromSearch Service Integration Test' do
  VcrHelper.setup_vcr

  before do
    VcrHelper.configure_vcr_for_services_add
  end

  after do
    VcrHelper.eject_vcr
  end

  describe 'Search and display relevant songs' do
    before do
      DatabaseHelper.wipe_database
    end

    it 'BAD: should gracefully fail for instrumental search query' do
      # GIVEN: valid search query but foreign artist
      bad_request = LyricLab::Forms::NewSearch.new.call(search_query: 'Vivaldi')

      # WHEN: the service is called with the request form object
      result = LyricLab::Service::FindSongsFromSearch.new.call(bad_request)

      # THEN: the service should report failure with an error message
      _(result.success?).must_equal false
      _(result.failure.downcase).must_include 'songs are not mandarin or have no lyrics'
    end

    it 'BAD: should gracefully fail for foreign artist search query' do
      # GIVEN: valid search query but foreign artist
      another_bad_request = LyricLab::Forms::NewSearch.new.call(search_query: 'ssshhhiiittt!')

      # WHEN: the service is called with the request form object
      result = LyricLab::Service::FindSongsFromSearch.new.call(another_bad_request)

      # THEN: the service should report failure with an error message
      _(result.success?).must_equal false
      _(result.failure.downcase).must_include 'songs are not mandarin or have no lyrics'
    end

    it 'BAD: should gracefully fail for empty search query' do
      # GIVEN: an invalid url request is formed
      missing_request = LyricLab::Forms::NewSearch.new.call(search_query: '')

      # WHEN: the service is called with the request form object
      result = LyricLab::Service::FindSongsFromSearch.new.call(missing_request)

      # THEN: the service should report failure with an error message
      _(result.success?).must_equal false
    end
  end
end
