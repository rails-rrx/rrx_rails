# frozen_string_literal: true

require 'rrx_rails/cli'

TEST_ALL_OPTIONS  = true
WHERE_ALL_OPTIONS = OptionInfo.all
                              .values
                              .map { |option|
                                [
                                  :"#{option.name}_option",
                                  TEST_ALL_OPTIONS ? [option, option.skip] : [option]
                                ]
                              }
                              .append([:case_names, OptionInfo.case_names])
                              .to_h
                              .freeze

FAKE_GEMFILE = <<~GEMFILE
  # My fake gemfile!
  source "https://rubygems.org"
  gem 'foo'
GEMFILE

RSpec.describe RrxRails::Cli do
  include_context 'fixtures'

  let(:project_type) { :api }
  let(:project_name) { 'blah_blah' }
  let(:project_options) { {} }
  let(:project_path) { temp_path.join(project_name).freeze }
  let(:run_cmds) { [] }
  let(:options) { OptionInfo.all.keys.map { |opt| send(:"#{opt}_option") }.freeze }
  let(:runtime_options) { options.select(&:runtime).map(&:option).freeze }
  let(:invoke_options) { options.map(&:option).compact.freeze }
  let(:new_options) { options.map(&:new_option).compact.freeze }
  let(:gemfile) { project_path.join('Gemfile').freeze }
  let(:gemfile_contents) { gemfile.read }
  let(:skip?) { skip_option.enabled? || pretend_option.enabled? }
  let(:jobs?) { jobs_option.enabled? }
  let(:valid_runtime_options?) { [force_option, skip_option, quiet_option, pretend_option].count(&:enabled?) <= 1 }

  let(:shell) do
    it = Thor::Shell::Basic.new

    allow(it).to receive(:ask_simply) do |message, *_args|
      puts "ask_simply: #{message}"
      ''
    end

    it
  end

  def setup_fake_project
    puts "Setting up fake project in #{project_path}"
    project_path.mkpath
    gemfile.write(FAKE_GEMFILE)
  end

  def mock_cli(cli)
    allow(cli).to receive(:run_cmd) do |*cmd, **_config|
      cmd.flatten!
      run_cmds << cmd
      puts "run_cmd: #{cmd.join(' ')}"

      setup_fake_project if cmd.include?('rails') && cmd.include?('new')
    end

    allow(cli).to receive(:run) do |cmd|
      run_cmds << cmd.split
      puts "run_cmd: #{cmd}"
    end
  end

  before do
    # Capture Thor commands for verification such as running commands
    allow(RrxRails::Cli).to receive(:new).and_wrap_original do |m, *args, **kwargs|
      m.call(*args, **kwargs).tap do |cli|
        mock_cli cli
      end
    end
  end

  after do
    expect(run_cmds).to be_empty, "Unmatched commands:\n#{formatted_commands}"
  end

  def formatted_commands
    run_cmds.map { |cmd| " > #{cmd.join(' ')}" }.join("\n")
  end

  # @param [Array<String>] cmd
  # @param [Array<String>] options
  # @param [Hash] _config
  def expect_cmd(cmd, options = [], **_config)
    cmd   += options.sort
    index = run_cmds.find_index { |it| it == cmd }

    expect(index).to_not be_nil,
                         "Could not find command: #{cmd.join(' ')}\n#{formatted_commands}"

    run_cmds.delete_at(index)
  end

  def invoke_action
    described_class.start(
      [project_type.to_s, project_path.to_s] + invoke_options,
      shell:,
      debug: true
    )
  end

  def expect_rails_new
    cmd = %w[gem exec -g rails --version]
    cmd << RrxRails::RAILS_VERSION
    cmd.concat project_type != :api ? %w[rails plugin new] : %w[rails new]
    cmd << project_path.to_s

    # api projects always include --database= (defaults to postgresql when --db not passed)
    db_flags = project_type == :api ? ['--database=postgresql'] : []
    expect_cmd cmd, new_options + RrxRails::Cli::RAILS_NEW_OPTIONS + db_flags
  end

  # Expects the three commands emitted by Cli#bundle_install.
  def expect_bundle_install
    expect_cmd %w[bundle config --delete bin]
    expect_cmd %w[bundle install]
    rails_bin_cmd = %w[gem exec -g rails --version]
    rails_bin_cmd << RrxRails::RAILS_VERSION
    rails_bin_cmd.concat %w[rails app:update:bin]
    expect_cmd rails_bin_cmd
  end

  describe 'api' do
    where(**WHERE_ALL_OPTIONS.dup)

    with_them do
      it 'should show an error if invalid runtime options are passed' do
        skip 'Valid runtime options' if valid_runtime_options?
        expect { invoke_action }.to raise_error(Thor::Error, /Only one of/)
        expect(project_path).to_not exist
      end

      it 'should create a new api project' do
        skip 'Invalid runtime options' unless valid_runtime_options?

        invoke_action
        expect_rails_new
        expect_bundle_install
        expect_cmd %w[bundle exec rails generate rrx_api:install], runtime_options
        expect_cmd %w[bundle exec rails generate rrx_jobs:install], runtime_options if jobs?

        if skip?
          expect(gemfile_contents).to eq FAKE_GEMFILE
        else
          expect(gemfile_contents).to include 'rrx_api'
          expect(gemfile_contents.rstrip).to end_with(described_class.comment(FAKE_GEMFILE.rstrip))

          expect(gemfile_contents).to include 'rrx_jobs' if jobs?
        end
      end
    end
  end

  describe 'railtie' do

  end

  describe 'engine' do

  end

  describe '--db option' do
    # Default skip flags added by rails_skip_options when no features are enabled.
    DB_TEST_FEATURE_SKIP_FLAGS = %w[
      --skip-action-cable
      --skip-action-mailer
      --skip-active-job
      --skip-active-storage
    ].freeze

    # Use a simple set of options: no runtime flags, no feature flags
    let(:invoke_options) { Array(defined?(db_value) ? ["--db=#{db_value}"] : []) }

    # Expect the full rails new command including feature skip flags and the given db adapter.
    def expect_rails_new_with_db(db_adapter)
      cmd = %w[gem exec -g rails --version]
      cmd << RrxRails::RAILS_VERSION
      cmd.concat %w[rails new]
      cmd << project_path.to_s

      db_flag = "--database=#{db_adapter}"
      all_flags = RrxRails::Cli::RAILS_NEW_OPTIONS + DB_TEST_FEATURE_SKIP_FLAGS + [db_flag]
      expect_cmd cmd, all_flags
    end

    context 'with --db=postgresql (default behaviour)' do
      let(:db_value) { 'postgresql' }

      it 'passes --database=postgresql to rails new' do
        invoke_action
        expect_rails_new_with_db('postgresql')
        expect_bundle_install
        expect_cmd %w[bundle exec rails generate rrx_api:install]
      end

      it 'includes the pg gem in the Gemfile' do
        invoke_action
        run_cmds.clear
        expect(gemfile_contents).to include("gem 'pg'")
      end
    end

    context 'with --db=sqlite' do
      let(:db_value) { 'sqlite' }

      it 'passes --database=sqlite3 to rails new' do
        invoke_action
        expect_rails_new_with_db('sqlite3')
        expect_bundle_install
        expect_cmd %w[bundle exec rails generate rrx_api:install]
      end

      it 'includes the sqlite3 gem in the Gemfile' do
        invoke_action
        run_cmds.clear
        expect(gemfile_contents).to include("gem 'sqlite3'")
      end
    end

    context 'with --db=mysql' do
      let(:db_value) { 'mysql' }

      it 'passes --database=mysql to rails new' do
        invoke_action
        expect_rails_new_with_db('mysql')
        expect_bundle_install
        expect_cmd %w[bundle exec rails generate rrx_api:install]
      end

      it 'includes the mysql2 gem in the Gemfile' do
        invoke_action
        run_cmds.clear
        expect(gemfile_contents).to include("gem 'mysql2'")
      end
    end

    context 'with --db=pg (alias for postgresql)' do
      let(:db_value) { 'pg' }

      it 'passes --database=postgresql to rails new' do
        invoke_action
        expect_rails_new_with_db('postgresql')
        expect_bundle_install
        expect_cmd %w[bundle exec rails generate rrx_api:install]
      end
    end

    context 'with an invalid --db value' do
      let(:db_value)       { 'oracle' }
      let(:invoke_options) { ['--db=oracle'] }

      it 'raises a Thor::Error with a descriptive message' do
        expect { invoke_action }
          .to raise_error(Thor::Error, /Invalid --db value 'oracle'/)
      end

      it 'lists valid options in the error message' do
        expect { invoke_action }
          .to raise_error(Thor::Error, /sqlite.*mysql.*postgresql/)
      end
    end

    context 'default db when --db is omitted' do
      let(:invoke_options) { [] }

      it 'defaults to --database=postgresql' do
        invoke_action
        expect_rails_new_with_db('postgresql')
        expect_bundle_install
        expect_cmd %w[bundle exec rails generate rrx_api:install]
      end
    end
  end

end
