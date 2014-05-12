# ENVied [![travis](https://secure.travis-ci.org/eval/envied.png?branch=master)](https://secure.travis-ci.org/#!/eval/envied)

### TL;DR ensure presence and type of your app's ENV-variables.

For applications that are configured via ENV-variables, this gem will provide:

* A fail-fast check for presence of required ENV-variables
* A fail-fast check for type of required ENV-variables
* Access to typed ENV-variables (instead of just strings)

### Current status

![](underconstruction.gif)

## Usage

### 1) Configure

Let's configure the ENV-variables we need:

```ruby
# e.g. config/application.rb
ENVied.configure do |env|
  env.variable :force_ssl, :Boolean
  env.variable :port, :Integer
end
```

### 2) Check for presence and type

```ruby
ENVied.require!
```
Excecution will halt unless ENV is something like
`{'FORCE_SSL' => 'false', 'PORT' => '3001'}`.

A meaningful error will in this case explain what key and type is needed.

### 3) Use typed variables

Variables accessed via ENVied have the configured type:

```ruby
ENVied.port # => 3001
ENVied.force_ssl # => false
```

## Configuration

### Types

The following types are supported:

* `:String` (implied)
* `:Boolean` (e.g. '0'/'1', 'f'/'t', 'false'/'true', 'off'/'on', 'yes','no' for resp. true or false)
* `:Integer`
* `:Symbol`
* `:Date` (e.g. '2014-3-26')
* `:Time` (e.g. '14:00')

### Defaults

In order to let other developers easily bootstrap the application, you can assign defaults to variables.
Defaults can be a value or a `Proc` (see example below).

Note that 'easily bootstrap' is quite the opposite of 'fail-fast when not all ENV-variables are present'. Therefor it's disabled by default and you should explicitly state whén it is allowed:

```ruby
ENVied.configure(enable_defaults: Rails.env.development?) do |env|
  env.variable :port, :Integer, default: proc {|env, variable| env.force_ssl ? 443 : 80 }
  env.variable :force_ssl, :Boolean, default: false
end
```

Please remember that ENVied only **reads** from ENV; don't let setting a default for, say `rails_env`, give you or your team the impression that `ENV['RAILS_ENV']` is set.  
As a rule of thumb: you should only use defaults:
* in a development-environment
* for ENV-variables that your application introduces (i.e. for `ENV['DEFAULT_SENDER']` not for `ENV['REDIS_URL']`)


## Installation

Add this line to your application's Gemfile:

    gem 'envied'

And then execute:

    $ bundle

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

1. Fork it ( http://github.com/eval/envied/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
