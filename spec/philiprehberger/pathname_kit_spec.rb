# frozen_string_literal: true

require 'digest'
require 'spec_helper'

RSpec.describe Philiprehberger::PathnameKit do
  let(:tmpdir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(tmpdir) }

  describe 'VERSION' do
    it 'has a version number' do
      expect(Philiprehberger::PathnameKit::VERSION).not_to be_nil
    end
  end

  describe '.atomic_write' do
    it 'writes content atomically' do
      path = File.join(tmpdir, 'test.txt')
      described_class.atomic_write(path) { |f| f.write('hello') }
      expect(File.read(path)).to eq('hello')
    end

    it 'creates parent directories' do
      path = File.join(tmpdir, 'nested', 'dir', 'test.txt')
      described_class.atomic_write(path) { |f| f.write('data') }
      expect(File.read(path)).to eq('data')
    end

    it 'raises on nil path' do
      expect { described_class.atomic_write(nil) { |f| f } }.to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises on empty path' do
      expect { described_class.atomic_write('') { |f| f } }.to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'cleans up temp file on error' do
      path = File.join(tmpdir, 'fail.txt')
      expect do
        described_class.atomic_write(path) { |_f| raise 'boom' }
      end.to raise_error(RuntimeError, 'boom')
      expect(File.exist?(path)).to be false
    end
  end

  describe '.ensure_directory' do
    it 'creates nested directories' do
      path = File.join(tmpdir, 'a', 'b', 'c')
      described_class.ensure_directory(path)
      expect(Dir.exist?(path)).to be true
    end

    it 'is idempotent' do
      path = File.join(tmpdir, 'existing')
      described_class.ensure_directory(path)
      described_class.ensure_directory(path)
      expect(Dir.exist?(path)).to be true
    end

    it 'raises on nil path' do
      expect { described_class.ensure_directory(nil) }.to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.safe_delete' do
    it 'deletes an existing file' do
      path = File.join(tmpdir, 'to_delete.txt')
      File.write(path, 'data')
      expect(described_class.safe_delete(path)).to be true
      expect(File.exist?(path)).to be false
    end

    it 'returns false for non-existent file' do
      expect(described_class.safe_delete(File.join(tmpdir, 'nope.txt'))).to be false
    end

    it 'raises on nil path' do
      expect { described_class.safe_delete(nil) }.to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.find' do
    it 'finds files matching a glob' do
      File.write(File.join(tmpdir, 'a.txt'), '')
      File.write(File.join(tmpdir, 'b.txt'), '')
      File.write(File.join(tmpdir, 'c.rb'), '')
      result = described_class.find(File.join(tmpdir, '*.txt'))
      expect(result.length).to eq(2)
      expect(result.all? { |f| f.end_with?('.txt') }).to be true
    end

    it 'returns empty array when no matches' do
      expect(described_class.find(File.join(tmpdir, '*.xyz'))).to eq([])
    end

    it 'raises on nil glob' do
      expect { described_class.find(nil) }.to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.tempfile' do
    it 'yields a temp file path' do
      described_class.tempfile('.txt') do |path|
        expect(path).to be_a(String)
        expect(File.exist?(path)).to be true
      end
    end

    it 'cleans up the temp file after block' do
      captured_path = nil
      described_class.tempfile('.txt') do |path|
        captured_path = path
      end
      expect(File.exist?(captured_path)).to be false
    end
  end

  describe '.touch' do
    it 'creates a new file' do
      path = File.join(tmpdir, 'touched.txt')
      described_class.touch(path)
      expect(File.exist?(path)).to be true
    end

    it 'creates parent directories' do
      path = File.join(tmpdir, 'deep', 'dir', 'file.txt')
      described_class.touch(path)
      expect(File.exist?(path)).to be true
    end

    it 'raises on nil path' do
      expect { described_class.touch(nil) }.to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.line_count' do
    it 'counts lines in a file' do
      path = File.join(tmpdir, 'lines.txt')
      File.write(path, "one\ntwo\nthree\n")
      expect(described_class.line_count(path)).to eq(3)
    end

    it 'returns zero for empty file' do
      path = File.join(tmpdir, 'empty.txt')
      File.write(path, '')
      expect(described_class.line_count(path)).to eq(0)
    end

    it 'raises for non-existent file' do
      expect { described_class.line_count(File.join(tmpdir, 'nope.txt')) }.to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises on nil path' do
      expect { described_class.line_count(nil) }.to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises on empty path' do
      expect { described_class.line_count('') }.to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'counts single line without trailing newline' do
      path = File.join(tmpdir, 'single.txt')
      File.write(path, 'hello')
      expect(described_class.line_count(path)).to eq(1)
    end
  end

  describe '.ensure_directory' do
    it 'raises on empty path' do
      expect { described_class.ensure_directory('') }.to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.safe_delete' do
    it 'raises on empty path' do
      expect { described_class.safe_delete('') }.to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.find' do
    it 'raises on empty glob' do
      expect { described_class.find('') }.to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'finds files in nested directories' do
      nested = File.join(tmpdir, 'sub')
      FileUtils.mkdir_p(nested)
      File.write(File.join(nested, 'deep.txt'), '')
      result = described_class.find(File.join(tmpdir, '**', '*.txt'))
      expect(result.any? { |f| f.include?('deep.txt') }).to be true
    end

    it 'returns sorted results' do
      File.write(File.join(tmpdir, 'z.txt'), '')
      File.write(File.join(tmpdir, 'a.txt'), '')
      result = described_class.find(File.join(tmpdir, '*.txt'))
      expect(result).to eq(result.sort)
    end
  end

  describe '.touch' do
    it 'raises on empty path' do
      expect { described_class.touch('') }.to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'updates mtime on existing file' do
      path = File.join(tmpdir, 'existing.txt')
      File.write(path, 'data')
      old_mtime = File.mtime(path)
      sleep(0.1)
      described_class.touch(path)
      expect(File.mtime(path)).to be >= old_mtime
    end
  end

  describe '.atomic_write' do
    it 'overwrites existing file content' do
      path = File.join(tmpdir, 'overwrite.txt')
      File.write(path, 'old')
      described_class.atomic_write(path) { |f| f.write('new') }
      expect(File.read(path)).to eq('new')
    end
  end

  describe '.tempfile' do
    it 'uses the given extension' do
      described_class.tempfile('.json') do |path|
        expect(path).to end_with('.json')
      end
    end

    it 'uses default .tmp extension' do
      described_class.tempfile do |path|
        expect(path).to end_with('.tmp')
      end
    end
  end

  describe '.copy' do
    it 'copies a file to the destination' do
      src = File.join(tmpdir, 'original.txt')
      dest = File.join(tmpdir, 'copied.txt')
      File.write(src, 'content')
      described_class.copy(src, dest)
      expect(File.read(dest)).to eq('content')
    end

    it 'creates parent directories' do
      src = File.join(tmpdir, 'src.txt')
      dest = File.join(tmpdir, 'deep', 'nested', 'copy.txt')
      File.write(src, 'data')
      described_class.copy(src, dest)
      expect(File.exist?(dest)).to be true
    end

    it 'returns the destination path' do
      src = File.join(tmpdir, 'a.txt')
      dest = File.join(tmpdir, 'b.txt')
      File.write(src, 'x')
      expect(described_class.copy(src, dest)).to eq(dest)
    end

    it 'raises for nil source' do
      expect { described_class.copy(nil, 'dest') }.to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises for missing source' do
      expect { described_class.copy('/nonexistent', File.join(tmpdir, 'x')) }.to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.move' do
    it 'moves a file to the destination' do
      src = File.join(tmpdir, 'original.txt')
      dest = File.join(tmpdir, 'moved.txt')
      File.write(src, 'content')
      described_class.move(src, dest)
      expect(File.exist?(dest)).to be true
      expect(File.exist?(src)).to be false
    end

    it 'creates parent directories' do
      src = File.join(tmpdir, 'src.txt')
      dest = File.join(tmpdir, 'deep', 'nested', 'moved.txt')
      File.write(src, 'data')
      described_class.move(src, dest)
      expect(File.exist?(dest)).to be true
    end

    it 'returns the destination path' do
      src = File.join(tmpdir, 'a.txt')
      dest = File.join(tmpdir, 'b.txt')
      File.write(src, 'x')
      expect(described_class.move(src, dest)).to eq(dest)
    end

    it 'raises for nil source' do
      expect { described_class.move(nil, 'dest') }.to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises for missing source' do
      expect { described_class.move('/nonexistent', File.join(tmpdir, 'x')) }.to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.checksum' do
    let(:file_path) { File.join(tmpdir, 'checksum.txt') }

    before { File.write(file_path, 'hello world') }

    it 'computes sha256 by default' do
      result = described_class.checksum(file_path)
      expect(result).to eq(Digest::SHA256.hexdigest('hello world'))
    end

    it 'computes md5' do
      result = described_class.checksum(file_path, algorithm: :md5)
      expect(result).to eq(Digest::MD5.hexdigest('hello world'))
    end

    it 'computes sha1' do
      result = described_class.checksum(file_path, algorithm: :sha1)
      expect(result).to eq(Digest::SHA1.hexdigest('hello world'))
    end

    it 'computes sha512' do
      result = described_class.checksum(file_path, algorithm: :sha512)
      expect(result).to eq(Digest::SHA512.hexdigest('hello world'))
    end

    it 'raises for unsupported algorithm' do
      expect { described_class.checksum(file_path, algorithm: :crc32) }.to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises for nil path' do
      expect { described_class.checksum(nil) }.to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises for missing file' do
      expect { described_class.checksum('/nonexistent') }.to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.read' do
    it 'reads file contents' do
      path = File.join(tmpdir, 'r.txt')
      File.write(path, 'hello')
      expect(described_class.read(path)).to eq('hello')
    end

    it 'raises for missing file' do
      expect { described_class.read('/nonexistent/r.txt') }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises for nil/empty path' do
      expect { described_class.read(nil) }.to raise_error(Philiprehberger::PathnameKit::Error)
      expect { described_class.read('') }.to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.write' do
    it 'writes content atomically and creates parents' do
      path = File.join(tmpdir, 'nested', 'w.txt')
      described_class.write(path, 'data')
      expect(File.read(path)).to eq('data')
    end

    it 'returns the destination path' do
      path = File.join(tmpdir, 'w.txt')
      expect(described_class.write(path, 'x')).to eq(path)
    end

    it 'raises for nil/empty path' do
      expect { described_class.write(nil, 'x') }.to raise_error(Philiprehberger::PathnameKit::Error)
      expect { described_class.write('', 'x') }.to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.each_line' do
    it 'yields each line' do
      path = File.join(tmpdir, 'lines.txt')
      File.write(path, "a\nb\nc\n")
      collected = []
      described_class.each_line(path) { |line| collected << line.chomp }
      expect(collected).to eq(%w[a b c])
    end

    it 'raises for missing file' do
      expect { described_class.each_line('/nonexistent') { |_| } }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.size' do
    it 'returns the file size in bytes' do
      path = File.join(tmpdir, 's.txt')
      File.write(path, 'hello')
      expect(described_class.size(path)).to eq(5)
    end

    it 'raises for missing file' do
      expect { described_class.size('/nonexistent') }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.with_tempdir' do
    it 'yields a directory that exists during the block' do
      observed = nil
      described_class.with_tempdir do |dir|
        observed = dir
        expect(Dir.exist?(dir)).to be true
        File.write(File.join(dir, 'a.txt'), 'x')
      end
      expect(Dir.exist?(observed)).to be false
    end

    it 'cleans up on exception' do
      observed = nil
      expect do
        described_class.with_tempdir do |dir|
          observed = dir
          raise 'boom'
        end
      end.to raise_error(RuntimeError, 'boom')
      expect(Dir.exist?(observed)).to be false
    end
  end

  describe '.append' do
    it 'appends content to an existing file' do
      described_class.with_tempdir do |dir|
        path = File.join(dir, 'log.txt')
        File.write(path, 'line1')
        described_class.append(path, "\nline2")
        expect(File.read(path)).to eq("line1\nline2")
      end
    end

    it 'creates the file if it does not exist' do
      described_class.with_tempdir do |dir|
        path = File.join(dir, 'new.txt')
        described_class.append(path, 'hello')
        expect(File.read(path)).to eq('hello')
      end
    end

    it 'creates parent directories' do
      described_class.with_tempdir do |dir|
        path = File.join(dir, 'a', 'b', 'deep.txt')
        described_class.append(path, 'deep')
        expect(File.read(path)).to eq('deep')
      end
    end

    it 'returns the path' do
      described_class.with_tempdir do |dir|
        path = File.join(dir, 'ret.txt')
        expect(described_class.append(path, 'x')).to eq(path)
      end
    end

    it 'raises for nil path' do
      expect { described_class.append(nil, 'x') }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises for empty path' do
      expect { described_class.append('', 'x') }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.identical?' do
    it 'returns true for files with identical contents' do
      described_class.with_tempdir do |dir|
        a = File.join(dir, 'a.txt')
        b = File.join(dir, 'b.txt')
        File.write(a, 'same')
        File.write(b, 'same')
        expect(described_class.identical?(a, b)).to be true
      end
    end

    it 'returns false for files with different contents' do
      described_class.with_tempdir do |dir|
        a = File.join(dir, 'a.txt')
        b = File.join(dir, 'b.txt')
        File.write(a, 'hello')
        File.write(b, 'world')
        expect(described_class.identical?(a, b)).to be false
      end
    end

    it 'raises for nil first path' do
      expect { described_class.identical?(nil, '/tmp/x') }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises for nil second path' do
      expect { described_class.identical?('/tmp/x', nil) }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises for missing file' do
      described_class.with_tempdir do |dir|
        a = File.join(dir, 'a.txt')
        File.write(a, 'x')
        expect { described_class.identical?(a, '/nonexistent') }
          .to raise_error(Philiprehberger::PathnameKit::Error)
      end
    end
  end

  describe '.empty?' do
    it 'returns true for an empty file' do
      described_class.with_tempdir do |dir|
        path = File.join(dir, 'empty.txt')
        File.write(path, '')
        expect(described_class.empty?(path)).to be true
      end
    end

    it 'returns false for a non-empty file' do
      described_class.with_tempdir do |dir|
        path = File.join(dir, 'data.txt')
        File.write(path, 'content')
        expect(described_class.empty?(path)).to be false
      end
    end

    it 'raises for nil path' do
      expect { described_class.empty?(nil) }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises for missing file' do
      expect { described_class.empty?('/nonexistent') }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.extension' do
    it 'returns the extension with leading dot' do
      expect(described_class.extension('/path/to/file.rb')).to eq('.rb')
    end

    it 'returns empty string for no extension' do
      expect(described_class.extension('/path/to/Makefile')).to eq('')
    end

    it 'returns the last extension for multiple dots' do
      expect(described_class.extension('archive.tar.gz')).to eq('.gz')
    end

    it 'raises for nil path' do
      expect { described_class.extension(nil) }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises for empty path' do
      expect { described_class.extension('') }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.expand' do
    it 'expands a relative path to absolute' do
      result = described_class.expand('file.txt')
      expect(result).to start_with('/')
      expect(result).to end_with('/file.txt')
    end

    it 'expands tilde to home directory' do
      result = described_class.expand('~/docs')
      expect(result).not_to include('~')
      expect(result).to end_with('/docs')
    end

    it 'returns absolute path unchanged' do
      expect(described_class.expand('/usr/local/bin')).to eq('/usr/local/bin')
    end

    it 'raises for nil path' do
      expect { described_class.expand(nil) }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises for empty path' do
      expect { described_class.expand('') }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.exists?' do
    it 'returns true for an existing file' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'test.txt')
        File.write(path, 'hello')
        expect(described_class.exists?(path)).to be true
      end
    end

    it 'returns true for an existing directory' do
      Dir.mktmpdir do |dir|
        expect(described_class.exists?(dir)).to be true
      end
    end

    it 'returns false for a non-existent path' do
      expect(described_class.exists?('/tmp/nonexistent_xyz_123')).to be false
    end

    it 'raises for nil path' do
      expect { described_class.exists?(nil) }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises for empty path' do
      expect { described_class.exists?('') }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.directory?' do
    it 'returns true for a directory' do
      Dir.mktmpdir do |dir|
        expect(described_class.directory?(dir)).to be true
      end
    end

    it 'returns false for a file' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'test.txt')
        File.write(path, 'hello')
        expect(described_class.directory?(path)).to be false
      end
    end

    it 'returns false for a non-existent path' do
      expect(described_class.directory?('/tmp/nonexistent_xyz_123')).to be false
    end

    it 'raises for nil path' do
      expect { described_class.directory?(nil) }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises for empty path' do
      expect { described_class.directory?('') }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.basename' do
    it 'returns the filename from a path' do
      expect(described_class.basename('/usr/local/bin/ruby')).to eq('ruby')
    end

    it 'returns the filename with extension' do
      expect(described_class.basename('/path/to/file.txt')).to eq('file.txt')
    end

    it 'returns the directory name for a trailing slash' do
      expect(described_class.basename('/path/to/dir/')).to eq('dir')
    end

    it 'raises for nil path' do
      expect { described_class.basename(nil) }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises for empty path' do
      expect { described_class.basename('') }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.dirname' do
    it 'returns the directory portion of a path' do
      expect(described_class.dirname('/usr/local/bin/ruby')).to eq('/usr/local/bin')
    end

    it 'returns the parent for a nested path' do
      expect(described_class.dirname('/path/to/file.txt')).to eq('/path/to')
    end

    it 'returns / for a root-level file' do
      expect(described_class.dirname('/file.txt')).to eq('/')
    end

    it 'raises for nil path' do
      expect { described_class.dirname(nil) }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises for empty path' do
      expect { described_class.dirname('') }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end

  describe '.mtime' do
    it 'returns a Time object for an existing file' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'test.txt')
        File.write(path, 'hello')
        result = described_class.mtime(path)
        expect(result).to be_a(Time)
      end
    end

    it 'returns a recent time for a newly created file' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'test.txt')
        File.write(path, 'hello')
        result = described_class.mtime(path)
        expect(result).to be_within(5).of(Time.now)
      end
    end

    it 'raises for a non-existent file' do
      expect { described_class.mtime('/tmp/nonexistent_xyz_123') }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises for nil path' do
      expect { described_class.mtime(nil) }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end

    it 'raises for empty path' do
      expect { described_class.mtime('') }
        .to raise_error(Philiprehberger::PathnameKit::Error)
    end
  end
end
