# frozen_string_literal: true

require_relative 'pathname_kit/version'
require 'fileutils'
require 'tempfile'
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

      Dir.glob(glob).sort
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
  end
end
