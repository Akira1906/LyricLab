# frozen_string_literal: true

require 'dry-validation'

module LyricLab
  module Forms
    # Form validation for search query
    class LangDifficulty < Dry::Validation::Contract
      # check for non empty search string
      LANG_DIFF_OPTIONS = ['', 'beginner', 'intermediate', 'advanced', 'expert', 'master']
      MSG_NO_LANG_DIFF = 'no language difficulty selected'

      params do
        required(:language_level).value(:string)
      end

      rule(:language_level) do
        key.failure(MSG_NO_LANG_DIFF) unless LANG_DIFF_OPTIONS.include?(value)
      end
    end
  end
end