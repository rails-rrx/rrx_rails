# RRX Rails

RRX Rails is the command-line interface to creating RRX-based Ruby on Rails web services and gems.

## Installation

This gem is intended to be installed globally:

```shell
gem install rrx_rails
```

## Usage

For full command-line syntax and options, please use `rrx_rails help`.

**Example: Creating a new Ruby on Rails API project with background jobs**

```shell
rrx_rails api path/to/new_project --jobs
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Update all gem versions

```shell
bundle exec rake rrx:update_versions[<NEW VERSION>]
```

### Install all gems locally

```shell
bundle exec rake rrx:install
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rails-rrx/rrx_rails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/rrx_rails/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RrxRails project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rrx_rails/blob/main/CODE_OF_CONDUCT.md).
