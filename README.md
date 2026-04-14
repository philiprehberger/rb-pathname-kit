# philiprehberger-pathname_kit

[![Tests](https://github.com/philiprehberger/rb-pathname-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-pathname-kit/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-pathname_kit.svg)](https://rubygems.org/gems/philiprehberger-pathname_kit)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-pathname-kit)](https://github.com/philiprehberger/rb-pathname-kit/commits/main)

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

### Copy and Move

```ruby
require "philiprehberger/pathname_kit"

Philiprehberger::PathnameKit.copy("src/config.yml", "backup/config.yml")
Philiprehberger::PathnameKit.move("tmp/upload.csv", "data/upload.csv")
```

### Read and Write

```ruby
Philiprehberger::PathnameKit.write("config/app.yml", "key: value")
Philiprehberger::PathnameKit.read("config/app.yml") # => "key: value"
```

### Streaming Lines and File Size

```ruby
Philiprehberger::PathnameKit.each_line("logs/app.log") do |line|
  puts line if line.include?("ERROR")
end

Philiprehberger::PathnameKit.size("logs/app.log") # => 4096
```

### Tempdir Helper

```ruby
Philiprehberger::PathnameKit.with_tempdir do |dir|
  File.write(File.join(dir, "scratch.txt"), "ephemeral")
  # directory is removed automatically
end
```

### Checksum

```ruby
require "philiprehberger/pathname_kit"

Philiprehberger::PathnameKit.checksum("data/file.bin")                    # SHA-256 (default)
Philiprehberger::PathnameKit.checksum("data/file.bin", algorithm: :md5)   # MD5
```

### Append

```ruby
Philiprehberger::PathnameKit.append("logs/app.log", "new entry\n")
```

### File Comparison

```ruby
Philiprehberger::PathnameKit.identical?("file_a.txt", "file_b.txt") # => true or false
```

### File Inspection

```ruby
Philiprehberger::PathnameKit.empty?("output.txt")        # => true or false
Philiprehberger::PathnameKit.extension("archive.tar.gz")  # => ".gz"
Philiprehberger::PathnameKit.expand("~/docs/notes.md")    # => "/home/user/docs/notes.md"
```

### Path Queries

```ruby
Philiprehberger::PathnameKit.exists?("config/app.yml")         # => true or false
Philiprehberger::PathnameKit.directory?("config")              # => true or false
Philiprehberger::PathnameKit.basename("/path/to/file.txt")     # => "file.txt"
Philiprehberger::PathnameKit.dirname("/path/to/file.txt")      # => "/path/to"
Philiprehberger::PathnameKit.mtime("config/app.yml")           # => 2026-04-14 12:00:00 +0000
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
| `.copy(src, dest)` | Copy file with parent directory creation |
| `.move(src, dest)` | Move file with parent directory creation |
| `.checksum(path, algorithm: :sha256)` | Compute file digest (md5, sha1, sha256, sha512) |
| `.read(path)` | Read a file's contents |
| `.write(path, content)` | Atomically write content, creating parent directories |
| `.each_line(path) { \|line\| }` | Stream a file line by line |
| `.size(path)` | File size in bytes |
| `.with_tempdir { \|dir\| }` | Yield a temporary directory and clean it up afterward |
| `.append(path, content)` | Append content to a file, creating parents if needed |
| `.identical?(path1, path2)` | Compare two files by SHA-256 digest |
| `.empty?(path)` | Check if a file is zero bytes |
| `.extension(path)` | Get the file extension (e.g. `".rb"`) |
| `.expand(path)` | Expand to absolute path with tilde expansion |
| `.exists?(path)` | Check if a file or directory exists |
| `.directory?(path)` | Check if a path is a directory |
| `.basename(path)` | Get the filename component of a path |
| `.dirname(path)` | Get the directory component of a path |
| `.mtime(path)` | Get the last modification time |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-pathname-kit)

🐛 [Report issues](https://github.com/philiprehberger/rb-pathname-kit/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-pathname-kit/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
