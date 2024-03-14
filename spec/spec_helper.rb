# frozen_string_literal: true

require 'rspec-parameterized'

Dir.glob(File.join(__dir__, 'support/**/*.rb')).each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

end
