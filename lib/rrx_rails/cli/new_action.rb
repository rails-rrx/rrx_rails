# # frozen_string_literal: true
# require_relative 'command_action'
#
# class NewAction < CommandAction
#   self.type = :new
#
#   desc 'api APP_PATH [OPTIONS]', 'Create a new API project'
#   mail!
#   storage!
#   jobs!
#   git!
#   def api(app_path)
#     @app_path = app_path
#     @app_type = :api
#
#     create_project
#     create_gemfile
#     bundle_install
#     configure_api
#   end
#
#   desc 'gem GEM_NAME [OPTIONS]', 'Create a new gem project'
#   git!
#   def gem(gem_name)
#     @app_path = gem_name
#     @app_type = :gem
#
#     create_project
#     create_gemspec
#     create_gemfile
#     bundle_install
#     configure_gem
#   end
#
#   private
#
#   RAILS_NEW_SKIP = %w[js hotwire jbuilder rubocop test bundle action-mailbox asset-pipeline].freeze
#   RAILS_NEW_OPTIONS = %w[--api].concat(RAILS_NEW_SKIP.map {|s| "--skip-#{s}"}).freeze
#
#   attr_reader :app_path, :app_type
#
#   def create_project
#     validate_name!
#     set_project_path
#
#     run rails_new_cmd
#
#     self.destination_root = Pathname.pwd.join(app_path)
#   end
#
#   def validate_name!
#     raise ArgumentError, 'Invalid project name' unless app_path =~ /^[a-z][a-z0-9]*([_-][a-z0-9]+)*$/
#   end
#
#   def set_project_path
#     @project_path = Pathname.pwd.join(app_path)
#     exit if project_path.exist? && !options[:force] && no?('Update existing project?')
#   end
#
#   def rails_new_cmd
#     cmd = %w[rails]
#     cmd << 'plugin' if gem?
#     cmd << 'new'
#     cmd << app_path
#     cmd.concat RAILS_NEW_OPTIONS
#
#     cmd << '--skip-git' if options[:skip_git]
#     cmd << '--skip-action-mailer' unless options[:mail]
#     cmd << '--skip-active-storage' unless options[:storage]
#     cmd << '--skip-active-job' unless options[:jobs]
#     cmd << '--force' if options[:force]
#
#     cmd.join(' ')
#   end
#
#   def create_gemfile
#     template 'gemfile.rb.erb', 'Gemfile', force: options[:force]
#   end
#
#   def create_gemspec
#     template 'gemspec.rb.erb', "#{app_path}.gemspec"
#   end
#
#   def bundle_install
#     inside(destination_root) { run 'bundle install' }
#   end
#
#   def configure_api
#     # Implementation for API configuration
#     inside(destination_root) { run "bundle exec rrx_api_setup #{force_flag}" }
#   end
#
#   def configure_gem
#     # Implementation for gem configuration
#     inside(destination_root) { run "bundle exec rrx_dev_setup #{force_flag} #{app_type}" }
#   end
#
#   def force_flag
#     options[:force] ? '--force' : ''
#   end
#
#   def gem?
#     app_type == :gem
#   end
#
#   def api?
#     app_type == :api
#   end
# end
