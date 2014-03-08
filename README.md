# ENVied or ENV on EPO

TL;DR `ENVied` will improve your life drama-ti-cally.

Say you're nicely configuring your app via ENV-variables, 'ey?
Then maybe, just like me, you had the itch to check whether all variables your app needs, are present.
Or you sometimes wish that ENV-variables should not only contain strings, but integers and booleans.
Wooha! You really should try `ENVied`.


## Installation

Add this line to your application's Gemfile:

    gem 'envied'

And then execute:

    $ bundle

## Usage

```ruby
# in config/application.rb
# somewhere after 'Bundler.require(*Rails.groups)':
ENVied.configure do |env|
  env.variable :rails_env
  env.variable :force_ssl, :Boolean
  env.variable :port, :Integer
end

ENVied.require! # raises when configured variables are not present in ENV

# existing app config starts here
module Blog
  class Application < Rails::Application
    config.force_ssl = ENVied.force_ssl
    ...
  end
end
```

## Testing

```bash
bundle install --binstubs

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
