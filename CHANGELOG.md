# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-04-10

### Added
- `append(path, content)` for appending content with parent directory creation
- `identical?(path1, path2)` for comparing two files by SHA-256 digest
- `empty?(path)` for checking if a file is zero bytes
- `extension(path)` for getting a file's extension
- `expand(path)` for expanding a path to its absolute form

## [0.3.0] - 2026-04-09

### Added
- `read(path)` for reading file contents with consistent error handling
- `write(path, content)` for atomic writes with automatic parent directory creation
- `each_line(path) { |line| }` for streaming a file line by line
- `size(path)` returning file size in bytes
- `with_tempdir { |dir| }` for temporary directories with automatic cleanup

## [0.2.0] - 2026-04-04

### Added
- `copy` method for file copying with parent directory creation
- `move` method for file moving with parent directory creation
- `checksum` method for computing file digests (MD5, SHA1, SHA256, SHA512)
- GitHub issue template gem version field
- Feature request "Alternatives considered" field

## [0.1.5] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.1.4] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.1.3] - 2026-03-24

### Fixed
- Standardize README code examples to use double-quote require statements

## [0.1.2] - 2026-03-24

### Fixed
- Fix Installation section quote style to double quotes
- Remove inline comments from Development section to match template

## [0.1.1] - 2026-03-22

### Changed
- Expand test coverage from 24 to 36 examples

## [0.1.0] - 2026-03-22

### Added
- Initial release
- Atomic file writes with temp file and rename
- Directory creation with ensure_directory
- Safe file deletion that returns success/failure
- Glob-based file finding
- Tempfile helper with automatic cleanup
- File touch with parent directory creation
- Line counting for files
