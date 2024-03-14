# frozen_string_literal: true

require 'thor'
require 'rails/generators'
require 'pathname'

class CommandAction < Thor
  include Thor::Actions
  include Rails::Generators::Actions

  APPLICATION_PATH = 'config/application.rb'.freeze
  GEM_ROOT = Pathname(__FILE__).parent.parent.expand_path.freeze
  RRX_ROOT = GEM_ROOT.parent.freeze
  RAILS_NEW_SKIP = %w[js hotwire jbuilder rubocop test bundle action-mailbox asset-pipeline].freeze
  RAILS_NEW_OPTIONS = %w[--api].concat(RAILS_NEW_SKIP.map {|s| "--skip-#{s}"}).freeze

  # noinspection RubyMismatchedArgumentType
  source_root Pathname(__dir__).join('sources')

  add_runtime_options!
  class_option :rrx_local, type: :boolean, desc: 'Use local RRX gems', default: false

  class << self
    attr_reader :type

    # rubocop:disable Style/OptionalBooleanParameter
    def banner(command, _namespace = nil, _subcommand = false)
      "#{basename} #{subcommand_prefix} #{command.usage}"
    end
    # rubocop:enable Style/OptionalBooleanParameter

    def subcommand_prefix
      name.gsub(/.*::/, '').gsub(/^[A-Z]/) { |match| match[0].downcase }.gsub(/[A-Z]/) { |match| "-#{match[0].downcase}" }
    end

    def exit_on_failure?
      true
    end

    def mail!
      option :mail, type: :boolean, desc: 'Include ActionMailer support'
    end

    def storage!
      option :storage, type: :boolean, desc: 'Include ActiveStorage support'
    end

    def jobs!
      option :jobs, type: :boolean, desc: 'Include ActiveJob support'
    end

    def sockets!
      options :sockets, type: :boolean, desc: 'Include ActionCable support'
    end

    def git!
      option :skip_git, type: :boolean, desc: 'Disable Git repo creation'
    end
  end
end

