# reloadable_midleware

Makes any Rack middleware reloadable. Or, rather - wraps a given piece of Rack middleware with a
special module, which will call `.new` on your middleware at `call()` time, not at instantiation
time. This means that the Rack application stack is not going to contain an object reference and
will be able to reload during constant teardown/setup.

## Usage

Replace your standard middleware initialization block:

```ruby
use CustomAuthentication, option: 'bar'
```

with this alteration:

```ruby
use ReloadableMiddleware.wrap(CustomAuthentication), option: 'bar'
```

This will make your middleware reloadable. In Rails, use

```ruby
Rails.application.config.middleware.use ReloadableMiddleware.wrap(MyMiddleware)
```

## Performance in production modes

If you are running with `RACK_ENV` set to `production` or with `Rails.env.production? == true`
the reloading will be disabled and you will have one instance of your middleware as usual. This
reduces object churn, since Rack assumes that your entire app stack is going to be built once
and then cached between requests - which helps performance.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'reloadable_middleware'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install reloadable_middleware

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/julik/reloadable_middleware.
