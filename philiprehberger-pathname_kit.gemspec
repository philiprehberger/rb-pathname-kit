# frozen_string_literal: true

require_relative 'lib/philiprehberger/pathname_kit/version'

Gem::Specification.new do |spec|
  spec.name = 'philiprehberger-pathname_kit'
  spec.version = Philiprehberger::PathnameKit::VERSION
  spec.authors = ['Philip Rehberger']
  spec.email = ['me@philiprehberger.com']

  spec.summary = 'Pathname extensions for atomic write, safe delete, and common file operations'
  spec.description = 'Pathname utility library providing atomic writes, safe deletes, directory ' \
                     'creation, glob-based file finding, tempfile helpers, touch, and line counting. ' \
                     'All operations handle edge cases and cleanup gracefully.'
  spec.homepage = 'https://philiprehberger.com/open-source-packages/ruby/philiprehberger-pathname_kit'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/philiprehberger/rb-pathname-kit'
  spec.metadata['changelog_uri'] = 'https://github.com/philiprehberger/rb-pathname-kit/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/philiprehberger/rb-pathname-kit/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
