# frozen_string_literal: true

require "thor"
require "pathname"

# rubocop:disable Style/Documentation
# rubocop:disable Metrics/ClassLength
class Command < Thor
  include Thor::Actions

  default_command :blah
  source_root Pathname(__FILE__).parent.join("sources")

  attr_reader :name,
              :type,
              :dependencies

  def self.exit_on_failure?
    true
  end

  desc "api NAME", "Create a new API project"
  # argument :name, type: :string, desc: "Name of the new project", aliases: %[-m]
  option :mail, type: :boolean, desc: "Include ActionMailer support"
  option :storage, type: :boolean, desc: "Include ActiveStorage support"

  def api(name)
    init name, :api
    rails_new(**options)
    create_gemfile
  end

  desc "railtie NAME", "Create a new Railtie project"
  def railtie(name)
    setup_gem name
  end

  desc "engine NAME", "Create a new Rails Engine project"
  option :mail, type: :boolean, desc: "Include ActionMailer support"
  option :storage, type: :boolean, desc: "Include ActiveStorage support"

  def engine(name)
    setup_gem name, engine: true, **options
  end

  protected

  def init(name, type = :gem, deps = [])
    @name         = name
    @type         = type
    @dependencies = deps
  end

  def module_name
    @module_name ||= name.gsub(/(^[a-z])|([^a-zA-Z][a-z])/) do |m|
      m[-1].upcase
    end
  end

  def gem?
    type == :gem
  end

  def api?
    type == :api
  end

  def ruby_version
    RUBY_VERSION
  end

  private

  RAILS_ARGS = %w[
    --skip-docker
    --skip-action-mailbox
    --skip-action-text
    --skip-active-job
    --skip-action-cable
    --skip-asset-pipeline
    --skip-javascript
    --skip-test
    --skip-bundle
    --api
  ].freeze

  def setup_gem(name, **options)
    init name
    rails_new(**options)
    create_gemspec
    create_gemfile
  end

  def rails_new(mail: false, storage: false, engine: false)
    unless name =~ /^[a-z][a-z0-9]*([_-][a-z0-9]+)*$/
      say_error "Invalid project name"
      exit 1
    end

    cmd = %w[rails]
    cmd << "plugin" if gem?
    cmd << "new"
    cmd << name
    cmd.concat RAILS_ARGS

    cmd << "--skip-action-mailer" unless mail
    cmd << "--skip-active-storage" unless storage
    cmd << "--skip-gemspec" if gem?

    puts cmd.join(" ")
    # run cmd.join(' ')

    self.destination_root = Pathname.pwd.join(name)
  end

  def create_gemspec
    template "gemspec.rb.erb", "#{name}.gemspec"
  end

  def create_gemfile
    template "gemfile.rb.erb", "Gemfile"
  end

  def bundle_install
    run "bundle install"
  end

  def rrx_api
    bundle_exec "rrx_api_setup"
  end

  def rrx_dev
    bundle_exec "rrx_dev_setup #{type}"
  end

  def bundle_exec(cmd)
    run "bundle exec #{cmd}"
  end

end
# rubocop:enable Style/Documentation
# rubocop:enable Metrics/ClassLength
