# Envied

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'envied'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install envied

## Usage

It can be used as follows:

```ruby
# app/models/app_config.rb
class AppConfig
  include Envied

  variable :force_ssl, Boolean
  variable :database_url
end

# config/application.rb
Bundler.require(*Rails.groups)

AppConfig.require # checks availability

module Blog
  class Application < Rails::Application
    config.force_ssl = AppConfig.force_ssl
  end
end
```

## Testing

```bash
bin/rspec
# or
bin/rake
```

## Developing

```bash
bin/pry --gem
```


## Contributing

1. Fork it ( http://github.com/<my-github-username>/envied/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
