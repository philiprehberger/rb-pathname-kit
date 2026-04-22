# frozen_string_literal: true

require_relative 'pathname_kit/version'
require 'digest'
require 'fileutils'
require 'tempfile'
require 'tmpdir'
require 'pathname'

module Philiprehberger
  module PathnameKit
    class Error < StandardError; end

    # Write content atomically by writing to a temp file then renaming.
    #
    # @param path [String] the file path to write to
    # @yield [IO] the temporary file to write to
    # @return [void]
    # @raise [Error] if path is nil or empty
    def self.atomic_write(path)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?

      dir = File.dirname(path)
      ensure_directory(dir)

      temp = Tempfile.new(['atomic', File.extname(path)], dir)
      begin
        yield temp
        temp.close
        FileUtils.mv(temp.path, path)
      rescue StandardError
        temp.close
        temp.unlink
        raise
      end
    end

    # Ensure a directory exists, creating it and all parents if needed.
    #
    # @param path [String] the directory path
    # @return [void]
    # @raise [Error] if path is nil or empty
    def self.ensure_directory(path)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?

      FileUtils.mkdir_p(path)
    end

    # Safely delete a file, returning true if deleted and false if not found.
    #
    # @param path [String] the file path to delete
    # @return [Boolean] true if the file was deleted
    # @raise [Error] if path is nil or empty
    def self.safe_delete(path)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?

      return false unless File.exist?(path)

      File.delete(path)
      true
    end

    # Find files matching a glob pattern.
    #
    # @param glob [String] the glob pattern
    # @return [Array<String>] matching file paths
    # @raise [Error] if glob is nil or empty
    def self.find(glob)
      raise Error, 'glob cannot be nil' if glob.nil?
      raise Error, 'glob cannot be empty' if glob.to_s.empty?

      Dir.glob(glob)
    end

    # Create a temporary file with a given extension and yield its path.
    #
    # @param ext [String] the file extension (e.g. '.txt')
    # @yield [String] the temporary file path
    # @return [Object] the block return value
    def self.tempfile(ext = '.tmp')
      temp = Tempfile.new(['tmp', ext])
      begin
        yield temp.path
      ensure
        temp.close
        temp.unlink
      end
    end

    # Touch a file, creating it if it does not exist and updating its mtime.
    #
    # @param path [String] the file path
    # @return [void]
    # @raise [Error] if path is nil or empty
    def self.touch(path)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?

      dir = File.dirname(path)
      ensure_directory(dir)
      FileUtils.touch(path)
    end

    # Count the number of lines in a file.
    #
    # @param path [String] the file path
    # @return [Integer] the number of lines
    # @raise [Error] if path is nil or empty
    # @raise [Error] if the file does not exist
    def self.line_count(path)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?
      raise Error, "file not found: #{path}" unless File.exist?(path)

      File.readlines(path).size
    end

    # Copies a file to a destination, creating parent directories as needed.
    #
    # @param src [String] source file path
    # @param dest [String] destination file path
    # @return [String] destination path
    # @raise [PathnameKit::Error] if src or dest is nil/empty, or src doesn't exist
    def self.copy(src, dest)
      raise Error, 'source path cannot be nil' if src.nil?
      raise Error, 'source path cannot be empty' if src.to_s.empty?
      raise Error, 'destination path cannot be nil' if dest.nil?
      raise Error, 'destination path cannot be empty' if dest.to_s.empty?
      raise Error, "source file does not exist: #{src}" unless File.exist?(src.to_s)

      dest_str = dest.to_s
      FileUtils.mkdir_p(File.dirname(dest_str))
      FileUtils.cp(src.to_s, dest_str)
      dest_str
    end

    # Moves a file to a destination, creating parent directories as needed.
    #
    # @param src [String] source file path
    # @param dest [String] destination file path
    # @return [String] destination path
    # @raise [PathnameKit::Error] if src or dest is nil/empty, or src doesn't exist
    def self.move(src, dest)
      raise Error, 'source path cannot be nil' if src.nil?
      raise Error, 'source path cannot be empty' if src.to_s.empty?
      raise Error, 'destination path cannot be nil' if dest.nil?
      raise Error, 'destination path cannot be empty' if dest.to_s.empty?
      raise Error, "source file does not exist: #{src}" unless File.exist?(src.to_s)

      dest_str = dest.to_s
      FileUtils.mkdir_p(File.dirname(dest_str))
      FileUtils.mv(src.to_s, dest_str)
      dest_str
    end

    # Read a file's contents.
    #
    # @param path [String] the file path
    # @return [String]
    # @raise [Error] if path is nil/empty or the file does not exist
    def self.read(path)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?
      raise Error, "file not found: #{path}" unless File.exist?(path.to_s)

      File.read(path.to_s)
    end

    # Atomically write content to a file, creating parent directories as needed.
    #
    # @param path [String] the file path
    # @param content [String] the content to write
    # @return [String] the path written
    # @raise [Error] if path is nil/empty
    def self.write(path, content)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?

      atomic_write(path.to_s) { |f| f.write(content.to_s) }
      path.to_s
    end

    # Stream a file line by line without loading it entirely into memory.
    #
    # @param path [String] the file path
    # @yield [String] each line, including the trailing newline if present
    # @return [Enumerator] when no block is given
    # @raise [Error] if path is nil/empty or the file does not exist
    def self.each_line(path, &block)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?
      raise Error, "file not found: #{path}" unless File.exist?(path.to_s)

      return File.foreach(path.to_s).each unless block

      File.foreach(path.to_s, &block)
    end

    # Get the size of a file in bytes.
    #
    # @param path [String] the file path
    # @return [Integer]
    # @raise [Error] if path is nil/empty or the file does not exist
    def self.size(path)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?
      raise Error, "file not found: #{path}" unless File.exist?(path.to_s)

      File.size(path.to_s)
    end

    # Create a temporary directory and yield its path. The directory and all its
    # contents are removed when the block returns.
    #
    # @yield [String] the temporary directory path
    # @return [Object] the block return value
    def self.with_tempdir
      dir = Dir.mktmpdir
      begin
        yield dir
      ensure
        FileUtils.rm_rf(dir)
      end
    end

    # Computes a digest checksum of a file.
    #
    # @param path [String] file path
    # @param algorithm [Symbol] :md5, :sha1, :sha256, or :sha512
    # @return [String] hex digest string
    # @raise [PathnameKit::Error] if path is nil/empty, file doesn't exist, or algorithm is invalid
    def self.checksum(path, algorithm: :sha256)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?

      path_str = path.to_s
      raise Error, "file does not exist: #{path_str}" unless File.exist?(path_str)

      digest_class = case algorithm
                     when :md5 then Digest::MD5
                     when :sha1 then Digest::SHA1
                     when :sha256 then Digest::SHA256
                     when :sha512 then Digest::SHA512
                     else raise Error, "unsupported algorithm: #{algorithm}"
                     end
      digest_class.file(path_str).hexdigest
    end

    # Append content to a file, creating parent directories if needed.
    # Creates the file if it does not exist.
    #
    # @param path [String] the file path
    # @param content [String] the content to append
    # @return [String] the path written
    # @raise [Error] if path is nil or empty
    def self.append(path, content)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?

      path_str = path.to_s
      ensure_directory(File.dirname(path_str))
      File.open(path_str, 'a') { |f| f.write(content.to_s) }
      path_str
    end

    # Compare two files by SHA-256 digest.
    #
    # @param path1 [String] first file path
    # @param path2 [String] second file path
    # @return [Boolean] true if files have identical contents
    # @raise [Error] if either path is nil/empty or does not exist
    def self.identical?(path1, path2)
      raise Error, 'first path cannot be nil' if path1.nil?
      raise Error, 'first path cannot be empty' if path1.to_s.empty?
      raise Error, 'second path cannot be nil' if path2.nil?
      raise Error, 'second path cannot be empty' if path2.to_s.empty?
      raise Error, "file does not exist: #{path1}" unless File.exist?(path1.to_s)
      raise Error, "file does not exist: #{path2}" unless File.exist?(path2.to_s)

      Digest::SHA256.file(path1.to_s).hexdigest == Digest::SHA256.file(path2.to_s).hexdigest
    end

    # Check if a file is empty (zero bytes).
    #
    # @param path [String] the file path
    # @return [Boolean] true if the file is empty
    # @raise [Error] if path is nil/empty or the file does not exist
    def self.empty?(path)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?
      raise Error, "file not found: #{path}" unless File.exist?(path.to_s)

      File.empty?(path.to_s)
    end

    # Get the file extension including the leading dot.
    #
    # @param path [String] the file path
    # @return [String] the extension (e.g. ".rb") or empty string
    # @raise [Error] if path is nil or empty
    def self.extension(path)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?

      File.extname(path.to_s)
    end

    # Expand a path to its absolute form with tilde expansion.
    #
    # @param path [String] the file path
    # @return [String] the expanded absolute path
    # @raise [Error] if path is nil or empty
    def self.expand(path)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?

      File.expand_path(path.to_s)
    end

    # Return +path+ expressed relative to +base+ as a String.
    #
    # Both arguments may be String or Pathname. Inputs are wrapped in
    # Pathname and expanded so relative inputs are resolved against the
    # current working directory before the relative path is computed.
    #
    # @param path [String, Pathname] the target path
    # @param base [String, Pathname] the base path to compute relativity against
    # @return [String] the relative path
    # @raise [Error] if either argument is nil or empty
    def self.relative_to(path, base)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?
      raise Error, 'base cannot be nil' if base.nil?
      raise Error, 'base cannot be empty' if base.to_s.empty?

      Pathname.new(path.to_s).expand_path.relative_path_from(Pathname.new(base.to_s).expand_path).to_s
    end

    # Check if a file or directory exists at the given path.
    #
    # @param path [String] the file or directory path
    # @return [Boolean] true if the path exists
    # @raise [Error] if path is nil or empty
    def self.exists?(path)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?

      File.exist?(path.to_s)
    end

    # Check if the given path is a directory.
    #
    # @param path [String] the path to check
    # @return [Boolean] true if the path is a directory
    # @raise [Error] if path is nil or empty
    def self.directory?(path)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?

      File.directory?(path.to_s)
    end

    # Get the filename component of a path (without directory).
    #
    # @param path [String] the file path
    # @return [String] the filename
    # @raise [Error] if path is nil or empty
    def self.basename(path)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?

      File.basename(path.to_s)
    end

    # Get the directory component of a path.
    #
    # @param path [String] the file path
    # @return [String] the directory portion
    # @raise [Error] if path is nil or empty
    def self.dirname(path)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?

      File.dirname(path.to_s)
    end

    # Get the last modification time of a file or directory.
    #
    # @param path [String] the file or directory path
    # @return [Time] the modification time
    # @raise [Error] if path is nil/empty or does not exist
    def self.mtime(path)
      raise Error, 'path cannot be nil' if path.nil?
      raise Error, 'path cannot be empty' if path.to_s.empty?
      raise Error, "path not found: #{path}" unless File.exist?(path.to_s)

      File.mtime(path.to_s)
    end
  end
end
