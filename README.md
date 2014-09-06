# ENVied [![travis](https://secure.travis-ci.org/eval/envied.png?branch=master)](https://secure.travis-ci.org/#!/eval/envied)

### TL;DR ensure presence and type of your app's ENV-variables.

## Features:

* check for presence and correctness of ENV-variables
* access to typed ENV-variables (integers, booleans etc. instead of just strings)
* check the presence and correctness of Heroku config

## Contents

* [Quickstart](#quickstart)
* [Installation](#installation)
* [Configuration](#configuration)
  * [Types](#types)
  * [Groups](#groups)
  * [Defaults](#defaults)
  * [More examples](#more-examples)
* [Rails](#rails)
* [Command-line interface](#command-line-interface)
* [Testing](#testing)
* [Developing](#developing)
* [Contributing](#contributing)

## Quickstart

### 1) Configure

After [successful installation](#installation), define some variables in `Envfile`:

```ruby
# file: Envfile
variable :FORCE_SSL, :Boolean
variable :PORT, :Integer
```

### 2) Check for presence and coercibility

```ruby
# during initialization
ENVied.require
```

This will throw an error if:
* not both `ENV['FORCE_SSL']` and `ENV['PORT']` are present.
* the values can't be coerced to resp. Boolean and Integer.

### 3) Use coerced variables

Variables accessed via ENVied are of the correct type:

```ruby
ENVied.PORT # => 3001
ENVied.FORCE_SSL # => false
```

## Installation

Add this line to your application's Gemfile:

    gem 'envied'

...then bundle:

    $ bundle

...then for Rails applications:

    $ bundle exec envied init:rails

...or for non-Rails applications:

    $ bundle exec envied init

## Configuration

### Types

The following types are supported:

* `:String` (implied)
* `:Boolean` (e.g. '0'/'1', 'f'/'t', 'false'/'true', 'off'/'on', 'no'/'yes' for resp. false and true)
* `:Integer`
* `:Symbol`
* `:Date` (e.g. '2014-3-26')
* `:Time` (e.g. '14:00')
* `:Hash` (e.g. 'a=1&b=2' becomes `{'a' => '1', 'b' => '2'}`)
* `:Array` (e.g. 'tag1,tag2' becomes `['tag1', 'tag2']`)

### Groups

Groups give you more flexibility to define when variables are needed.  
It's similar to groups in a Gemfile:

```ruby
# file: Envfile
variable :FORCE_SSL, :Boolean

group :production do
  variable :NEW_RELIC_LICENSE_KEY
end
```

```ruby
# For local development you would typically do:
ENVied.require(:default) #=> Only ENV['FORCE_SSL'] is required
# On the production server:
ENVied.require(:default, :production) #=> ...also ENV['NEW_RELIC_LICENSE_KEY'] is required

# BTW the following are equivalent:
ENVied.require
ENVied.require(:default)
ENVied.require('default')
ENVied.require(nil)
```

### Defaults

In order to let other developers easily bootstrap the application, you can assign defaults to variables.
Defaults can be a value or a `Proc` (see example below).

Note that 'easily bootstrap' is quite the opposite of 'fail-fast when not all ENV-variables are present'. Therefor you should explicitly state whén defaults are allowed:

```ruby
# Envfile
enable_defaults! { ENV['RACK_ENV'] == 'development' }

variable :FORCE_SSL, :Boolean, default: false
variable :PORT, :Integer, default: proc {|envied| envied.FORCE_SSL ? 443 : 80 }
```

Please remember that ENVied only **reads** from ENV; it doesn't mutate ENV.
Don't let setting a default for, say `RAILS_ENV`, give you the impression that `ENV['RAILS_ENV']` is set.  
As a rule of thumb you should only use defaults:
* for local development
* for ENV-variables that your application introduces (i.e. for `ENV['STAFF_EMAILS']` not for `ENV['REDIS_URL']`)

### More examples

* See the [examples](/examples)-folder for a more extensive Envfile
* See [the Envfile](https://github.com/eval/bunny_drain/blob/c54d7d977afb5e23a92da7a2fd0d39f6a7e29bf1/Envfile) for the bunndy_drain application

## Rails

**tl;dr** use the `init:rails`-task to generate the necessary files for a Rails app (see [installation](#installation)).

---

With the [Spring](https://github.com/rails/spring) preloader (which is part of the default Rails setup nowadays) it's a bit tricky when to do `ENVied.require`.

The first time you execute a command (say `bin/rails console`), Spring will start the server from which subsequent commands fork from.  
Currently [a bug in Spring](https://github.com/rails/spring/pull/267#issue-28580171) causes the initialization of the forked process to use the server's `ENV` instead of the actual `ENV`.  

So if your `ENV` is not valid the first time you start Spring...:

    # spring server *not* running
    $ bin/rails console
    # spring server started
    # error raised: Please set the following ENV-variables: FORCE_SSL (RuntimeError)

...it won't be valid for subsequent commands (even when you provide the correct variables):

    # spring server still running
    # FORCE_SSL=1 bin/rails console
    # error raised: Please set the following ENV-variables: FORCE_SSL (RuntimeError)

So while doing a `ENVied.require` in `config/application.rb` would seem perfectly fine, it won't work in the default 'springified' Rails setup.

The workaround (which the `init:rails`-task will generate) is to move the `ENVied.require` to Spring's `after_fork`-callback.  
If you want to change Rails' config based on ENV-variables you should put this in an `after_fork`-callback as well:

```ruby
# config/initializers/envied.rb as generated by 'bundle exec envied init:rails'
ENVied.springify do
  ENVied.require(:default, ENV['RAILS_ENV'])

  Rails.configuration.force_ssl = ENVied.FORCE_SSL
end
```

## Command-line interface

```bash
$ envied help
Commands:
  envied --version             # Shows version number
  envied check                 # Checks whether you environment contains the defined variables
  envied check:heroku          # Checks whether a Heroku config contains the defined variables
  envied check:heroku:binstub  # Generates a shell script for the check:heroku-task
  envied extract               # Shows candidate variables (i.e. occurences of ENV['X'])
  envied help [COMMAND]        # Describe available commands or one specific command
  envied init                  # Generates a default Envfile in the current working directory
  envied init:rails            # Generate all files needed for a Rails project
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

1. Fork it ( http://github.com/eval/envied/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
