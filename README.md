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
ENVied::Configure do |env|
  env.variable :force_ssl, Boolean
  env.variable :rails_env
end

ENVied.require! # raise when not all configured variables are present
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
