# frozen_string_literal: true
require 'pathname'

TEMP_PATH = Pathname(__FILE__).join('../../../tmp/test').expand_path.freeze

shared_context 'fixtures' do
  before :each do
    if TEMP_PATH.exist?
      TEMP_PATH.rmtree
    end
  end

  let(:temp_path) do
    TEMP_PATH.mkpath unless TEMP_PATH.exist?
    TEMP_PATH
  end
end
