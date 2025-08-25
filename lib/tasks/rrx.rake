# frozen_string_literal: true

require 'pathname'

# Base class for RRX tasks.
class RrxTask
  ROOT_PATH = begin
                it = Pathname(__FILE__).expand_path
                it = it.parent until it.join('lib').exist?
                it.parent.freeze
              end
  GEMS = %w[dev config logging api jobs rails].map { |n| "rrx_#{n}" }.freeze

  def each_gem(&block)
    puts ROOT_PATH.to_s
    GEMS.map { |name| ROOT_PATH.join(name) }.select(&:directory?).each do |path|
      block.call path
    end
  end
end

# Updates RRX gem versions.
class UpdateGems < RrxTask
  attr_reader :version

  # @param [String] version
  def initialize(version)
    super()

    # @type [String]
    @version = version.to_s.strip

    raise ArgumentError, 'Invalid version' if @version.empty?
  end

  def update_gems
    each_gem { |dir| update_directory dir }
  end

  private

  # @param [Pathname] path
  def update_file(path)
    text = path.read
    new_contents = text.gsub(/(\sVERSION\s*=\s*['"])([^'"]+)(['"])/, "\\1#{version}\\3")
    return if new_contents == text

    puts "Updating #{path} to version #{version}"
    path.write new_contents
  end

  # @param [Pathname] path
  def update_directory(path)
    path.glob('**/version.rb').each do |version_path|
      update_file version_path
    end
  end
end

# Installs RRX gems locally.
class InstallTask < RrxTask
  def install_gems
    each_gem { |dir| install_directory dir }
  end

  private

  # @param [Pathname] path
  def install_directory(path)
    Dir.chdir path do
      raise 'Failed to build gem!' unless build(path)
      raise 'Failed to install gem!' unless install(path)
    end
  end

  def build(path)
    Dir.chdir path do
      return system('rake build')
    end
  end

  def install(path)
    pkg = path.join('pkg').glob('*.gem').max_by(&:mtime)
    pkg && system("gem install -N --ignore-dependencies #{pkg}")
  end
end

namespace :rrx do

  desc 'Update RRX gem versions.'
  task :update_versions, [:version] do |t, args|
    updater = UpdateGems.new(args[:version])
    updater.update_gems
  end

  desc 'Install RRX gems locally.'
  task :install do
    InstallTask.new.install_gems
  end
end
