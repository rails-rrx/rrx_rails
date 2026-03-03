class OptionInfo
  attr_reader :name, :skip, :runtime, :new_option, :skipped

  # @return [Hash]
  def self.all
    @all ||= {}
  end

  # @param [Array<OptionInfo>] options
  def self.case_names(*options)
    "Options: #{options.select(&:enabled?).map(&:option).join(" ")}"
  end

  # @param [Symbol] name
  # @param [String] option
  # @param [String] new_option
  # @param [String] skip_option
  def self.add(name, option: nil, new_option: nil, skip_option: nil, runtime: false)
    option ||= "--#{name.to_s.gsub("_", "-")}"

    all[name.to_sym] = new(
      name,
      runtime:,
      option:,
      new_option: skip_option ? new_option : new_option || option,
      skip_option:
    ).freeze
  end

  # @param [Symbol] name
  # @param [String] option
  # @param [String, Boolean] new_option
  # @param [String] skip_option
  def initialize(name, option:, new_option:, skip_option: nil, skipped: false, runtime: false)
    @name        = name.to_sym
    @option      = option
    @runtime     = runtime
    @new_option  = new_option
    @skip_option = skip_option
    @skipped     = skipped
    @skip        = OptionInfo.new(name, option:, new_option: @skip_option, skipped: true).freeze unless @skipped
  end

  def enabled?
    !@skipped
  end

  def to_s
    name
  end

  def option
    @skipped ? nil : @option
  end

  add :force, runtime: true
  add :quiet, runtime: true
  add :pretend, runtime: true
  add :skip, runtime: true
  add :skip_git
  add :storage, skip_option: '--skip-active-storage'
  add :sockets, skip_option: '--skip-action-cable'
  add :mail, skip_option: '--skip-action-mailer'
  add :jobs, skip_option: '--skip-active-job'

  # --db is a string-valued option, not boolean; it does not have a skip/enable pair.
  # Instead it is tested separately in cli_spec.rb rather than through the WHERE_ALL_OPTIONS matrix.
  DB_VALUES = %w[postgresql sqlite mysql pg].freeze
end
