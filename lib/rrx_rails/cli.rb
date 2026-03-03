# frozen_string_literal: true

require 'thor'
require 'pathname'
require_relative './version'

# rubocop:disable Style/Documentation
# rubocop:disable Metrics/ClassLength

module RrxRails
  class Cli < Thor
    include Thor::Actions

    add_runtime_options!

    class_option :rrx_local, type: :boolean, desc: 'Use local RRX gems', default: false, hide: true
    class_option :skip_git, type: :boolean, desc: 'Disable Git repo creation', default: false
    class_option :update, type: :boolean, desc: 'Update an existing project', default: false

    class << self
      def exit_on_failure?
        true
      end

      def comment(str)
        str.gsub(/^([^#])/m, '#\1')
      end

      private

      def mail!
        option :mail, type: :boolean, desc: 'Include ActionMailer support'
      end

      def storage!
        option :storage, type: :boolean, desc: 'Include ActiveStorage support'
      end

      def db!
        option :db, type: :string, desc: 'Database type (sqlite, mysql, postgresql)', default: 'postgresql'
      end

      def jobs!
        option :jobs, type: :boolean, desc: 'Include ActiveJob support'
      end

      def sockets!
        option :sockets, type: :boolean, desc: 'Include ActionCable support'
      end
    end

    #
    # # default_command :api
    source_root Pathname(__FILE__).parent.join('cli/sources').freeze
    #
    # attr_reader :name,
    #             :type,
    #             :dependencies,
    #             :existed,
    #             :project_path

    desc 'api APP_PATH', 'Create a new API project'
    db!
    mail!
    storage!
    jobs!
    sockets!

    def api(name)
      validate_options!
      validate_db!
      init name, type: :api
      create_project
      inside do
        create_gemfile
        bundle_install
        generate 'rrx_api:install'
        generate 'rrx_jobs:install' if options[:jobs]
      end
    end

    desc 'railtie APP_PATH', 'Create a new Railtie project'
    def railtie(name)
      validate_options!
      setup_gem name
    end

    desc 'engine APP_PATH', 'Create a new Rails Engine project'
    mail!
    storage!

    def engine(name)
      validate_options!
      setup_gem name, engine: true
    end

    private

    GEM_ROOT = begin
                 path = Pathname(__FILE__)
                 path = path.parent until path.join('lib').exist? || path.root?
                 raise "Cannot find gem root from #{__FILE__}" if path.root?

                 path.realpath.freeze
               end

    RRX_ROOT          = GEM_ROOT.parent.freeze
    RAILS_NEW_SKIP    = %w[js hotwire jbuilder rubocop test bundle action-mailbox asset-pipeline].freeze
    RAILS_NEW_OPTIONS = %w[--api].concat(RAILS_NEW_SKIP.map { |s| "--skip-#{s}" }).freeze

    DB_MAP = {
      'sqlite'       => 'sqlite3',
      'mysql'        => 'mysql',
      'postgresql'   => 'postgresql',
      'pg'           => 'postgresql'
    }.freeze

    DB_GEM = {
      'sqlite3'      => 'sqlite3',
      'mysql'        => 'mysql2',
      'postgresql'   => 'pg'
    }.freeze

    attr_reader :app_name, :type, :dependencies, :app_path

    def setup_gem(name, engine: false)
      @engine = engine

      init name, deps: %w[rrx_logging rrx_config]
      create_project
      create_gemspec
      create_gemfile
      bundle_install
      generate 'rrx_dev:install'
    end

    # @param [String] app_path
    # @param [Symbol] type
    # @param [Array<String>] deps
    def init(app_path, type: :gem, deps: [])
      basename = Pathname(app_path).basename.to_s
      raise Thor::Error, 'Invalid app name' if basename !~ /^[a-z][a-z0-9_]*$/

      @app_path     = Pathname(app_path).expand_path
      @app_name     = @app_path.basename.to_s
      @type         = type
      @dependencies = deps
    end

    def validate_options!
      return unless [force?, skip?, pretend?, quiet?].count(true) > 1

      raise Thor::Error, 'Only one of --force, --skip, --pretend or --quiet is allowed'
    end

    def validate_db!
      return unless options.key?(:db)

      raise Thor::Error, "Invalid --db value '#{options[:db]}'. Valid options: #{DB_MAP.keys.join(', ')}" unless DB_MAP.key?(options[:db])
    end

    def comment(str)
      Cli.comment str
    end

    def force?
      options[:force]
    end

    def quiet?
      options[:quiet]
    end

    def pretend?
      options[:pretend]
    end

    def skip?
      options[:skip]
    end

    def runtime_options
      @runtime_options ||= begin
                             cmd = []
                             cmd << '--force' if force?
                             cmd << '--quiet' if quiet?
                             cmd << '--pretend' if pretend?
                             cmd << '--skip' if skip?
                             cmd.sort.freeze
                           end
      @runtime_options
    end

    def rails_skip_options
      cmd = []
      cmd << '--skip-git' if options[:skip_git]
      cmd << '--skip-action-mailer' unless options[:mail]
      cmd << '--skip-active-storage' unless options[:storage]
      cmd << '--skip-active-job' unless options[:jobs]
      cmd << '--skip-action-cable' unless options[:sockets]
      cmd << "--database=#{DB_MAP.fetch(options[:db], 'postgresql')}" if api?
      cmd
    end

    def rrx_version
      @rrx_version ||= "~> #{RrxRails::VERSION}"
    end

    alias rails_version rrx_version

    def rails_cmd(*args)
      ['gem', 'exec', '-g', 'rails', '--version', rails_version, 'rails', *args].flatten
    end

    def rails_new_cmd
      cmd = gem? ? %w[plugin new] : %w[new]
      cmd << app_path.to_s

      cmd_options = runtime_options.dup
      cmd_options << '--mountable' if engine?
      cmd_options.concat RAILS_NEW_OPTIONS
      cmd_options.concat rails_skip_options

      rails_cmd cmd + cmd_options.sort
    end

    def bundle_install
      inside(destination_root) { run 'bundle config --delete bin' }
      inside(destination_root) { run 'bundle install' }
      fix_rails_binstubs
    end

    def fix_rails_binstubs
      run_cmd rails_cmd('app:update:bin')
    end

    def gem?
      type == :gem
    end

    def api?
      type == :api
    end

    def engine?
      gem? && @engine
    end

    def ruby_version
      RUBY_VERSION
    end

    def generate(name)
      inside { run_cmd %w[bundle exec rails generate], name, runtime_options }
    end

    def create_project
      run_cmd rails_new_cmd unless options[:update]
      self.destination_root = app_path
    end

    def create_gemspec
      template 'gemspec.rb.erb', "#{name}.gemspec"
    end

    def create_gemfile
      template 'gemfile.rb.erb', 'Gemfile', force: force_gemfile?
    end

    def force_gemfile?
      return false if skip?

      !existing_gemfile.include?('rrx')
    end

    def existing_gemfile
      @existing_gemfile ||= begin
                              text                        = app_path.join('Gemfile').read
                              idx                         = text.index('# Please review')
                              @commented_existing_gemfile = text[idx...].lines[2...].join('') if idx
                              text
                            end
    end

    def commented_existing_gemfile
      @commented_existing_gemfile ||= comment(existing_gemfile)
    end

    def run_cmd(*command, **config)
      run(
        command.flatten.map do |s|
          s =~ /\s/ ? "'#{s}'" : s
        end.join(' '),
        config
      )
    end

    def rrx_gem_spec(name)
      spec = "gem '#{name}', RRX_VERSION"
      spec += ", path: '#{RRX_ROOT.join(name)}'" if options[:rrx_local]
      spec
    end

    def gem_list
      gems = [
        rrx_gem_spec('rrx_api')
      ]
      gems << rrx_gem_spec('rrx_jobs') if options[:jobs]
      gems << "gem '#{db_gem}'" if db_gem
      gems
    end

    def db_gem
      return nil unless api?

      db_adapter = DB_MAP.fetch(options.fetch(:db, 'postgresql'), 'postgresql')
      DB_GEM[db_adapter]
    end

    def dev_gem_list
      [rrx_gem_spec('rrx_dev')]
    end

  end

end

# rubocop:enable Style/Documentation
# rubocop:enable Metrics/ClassLength
