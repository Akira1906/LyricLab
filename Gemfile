# frozen_string_literal: true

source 'https://rubygems.org'
ruby File.read('.ruby-version').strip

# Configuration and Utilities
gem 'figaro', '~> 1.0'
gem 'ostruct'
gem 'pry'
gem 'rake'

# Data Validation
gem 'dry-struct', '~> 1.6'
gem 'dry-types', '~> 1.7'

# Web Application
gem 'logger', '~> 1.6'
gem 'puma', '~>6.0'
gem 'roda', '~>3.0'
gem 'slim', '~>4.0'

# Networking
gem 'http', '~> 5.2.0'

# Database
gem 'hirb'

#
gem 'rest-client'
# gem 'hirb-unicode' # incompatible with new rubocop
gem 'sequel', '~> 5.0'

# Word Processing
gem 'tradsim'
gem 'csv'

group :development, :test do
  gem 'sqlite3', '~> 1.0'
  gem 'roo'
end

group :production do
  gem 'pg'
end

# Testing
group :test do
  gem 'minitest', '~> 5.20'
  gem 'minitest-rg', '~> 5.2'
  gem 'simplecov', '~> 0'
  gem 'vcr', '~> 6'
  gem 'webmock', '~> 3'
end

# Development
group :development do
  gem 'flog'
  gem 'reek'
  gem 'rerun'
  gem 'rubocop'
  gem 'rubocop-minitest'
  gem 'rubocop-rake'
  gem 'ruby-lsp'
end
