# frozen_string_literal: true

require "rrx_rails/command"

RSpec.describe "rrx_rails" do
  let(:project_name) { "blah-blah" }

  def in_tmp(&block)
    tmp = Pathname(__FILE__).join("../../tmp")
    if tmp.exist?
      tmp.each_child(&:rmtree)
    else
      tmp.mkpath
    end

    Dir.chdir(tmp.to_s, &block)
  end

  def run(type, *args)
    in_tmp do
      cmd = Command.new
      cmd.invoke(type.to_s, [project_name] + args)
    end
  end

  it "creates an engine" do
    run :engine
  end
end
