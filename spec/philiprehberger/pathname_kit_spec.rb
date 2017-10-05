# frozen_string_literal: true

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
end
