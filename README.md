# philiprehberger-pathname_kit

[![Tests](https://github.com/philiprehberger/rb-pathname-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-pathname-kit/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-pathname_kit.svg)](https://rubygems.org/gems/philiprehberger-pathname_kit)
[![License](https://img.shields.io/github/license/philiprehberger/rb-pathname-kit)](LICENSE)

Pathname extensions for atomic write, safe delete, and common file operations

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-pathname_kit"
```

Or install directly:

```bash
gem install philiprehberger-pathname_kit
```

## Usage

```ruby
require "philiprehberger/pathname_kit"

Philiprehberger::PathnameKit.atomic_write('config.yml') do |f|
  f.write('key: value')
end
```

### Atomic Write

```ruby
Philiprehberger::PathnameKit.atomic_write('/path/to/file.txt') do |f|
  f.write('safe content')
end
```

### Directory and File Operations

```ruby
Philiprehberger::PathnameKit.ensure_directory('/path/to/nested/dir')
Philiprehberger::PathnameKit.touch('/path/to/file.txt')
Philiprehberger::PathnameKit.safe_delete('/path/to/old.txt')  # => true or false
```

### Finding and Counting

```ruby
files = Philiprehberger::PathnameKit.find('/src/**/*.rb')
count = Philiprehberger::PathnameKit.line_count('/path/to/file.rb')
```

### Tempfile Helper

```ruby
Philiprehberger::PathnameKit.tempfile('.csv') do |path|
  File.write(path, 'a,b,c')
  # temp file is cleaned up automatically
end
```

## API

| Method | Description |
|--------|-------------|
| `.atomic_write(path) { \|f\| }` | Write to a temp file then rename atomically |
| `.ensure_directory(path)` | Create directory and all parents if needed |
| `.safe_delete(path)` | Delete a file, returning true if deleted |
| `.find(glob)` | Find files matching a glob pattern |
| `.tempfile(ext) { \|path\| }` | Create a temp file and yield its path |
| `.touch(path)` | Create or update a file's modification time |
| `.line_count(path)` | Count the number of lines in a file |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
