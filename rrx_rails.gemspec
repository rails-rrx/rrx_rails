# frozen_string_literal: true

require_relative "lib/rrx_rails/version"

Gem::Specification.new do |spec|
  source_uri = 'https://github.com/rails-rrx/rrx_rails'
  home_uri = source_uri

  spec.name = "rrx_rails"
  spec.version = RrxRails::VERSION
  spec.authors = ["Dan Drew"]
  spec.email = ["dan.drew@hotmail.com"]

  spec.summary = "Command line for creating RRX projects"
  # spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = home_uri
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = source_uri
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  # spec.require_paths = ["lib"]

  spec.add_dependency "thor"
end
