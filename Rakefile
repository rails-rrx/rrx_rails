# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'pathname'

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

Pathname(__FILE__).join('../lib/tasks').glob('**/*.rake').each { |f| load f }

task default: %i[spec rubocop]
