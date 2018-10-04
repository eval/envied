# ENVied [![Build Status](https://travis-ci.org/eval/envied.svg?branch=master)](https://travis-ci.org/eval/envied)

### TL;DR ensure presence and type of your app's ENV-variables.

For the rationale behind this project, see this [blogpost](http://www.gertgoet.com/2014/10/14/envied-or-how-i-stopped-worrying-about-ruby-s-env.html).

## Features:

* check for presence and correctness of ENV-variables
* access to typed ENV-variables (integers, booleans etc. instead of just strings)
* check the presence and correctness of a Heroku config

## Contents

* [Quickstart](#quickstart)
* [Installation](#installation)
* [Configuration](#configuration)
  * [Types](#types)
  * [Groups](#groups)
  * [Defaults](#defaults)
  * [More examples](#more-examples)
* [Command-line interface](#command-line-interface)
* [How do I...?](#how-do-i)
* [Testing](#testing)
* [Developing](#developing)
* [Contributing](#contributing)

## Quickstart

### 1) Configure

After [successful installation](#installation), define some variables in `Envfile`:

```ruby
# file: Envfile
variable :FORCE_SSL, :boolean
variable :PORT, :integer
```

### 2) Check for presence and coercibility

```ruby
# during initialization
ENVied.require
```

This will throw an error if:
* both `ENV['FORCE_SSL']` and `ENV['PORT']` are *not present*.
* the values *cannot* be coerced to a boolean and integer.

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

* `:string` (implied)
* `:boolean` (e.g. '0'/'1', 'f'/'t', 'false'/'true', 'off'/'on', 'no'/'yes' for resp. false and true)
* `:integer`
* `:float`
* `:symbol`
* `:date` (e.g. '2014-3-26')
* `:time` (e.g. '14:00')
* `:hash` (e.g. 'a=1&b=2' becomes `{'a' => '1', 'b' => '2'}`)
* `:array` (e.g. 'tag1,tag2' becomes `['tag1', 'tag2']`)
* `:uri` (e.g. 'http://www.google.com' becomes `URI.parse('http://www.google.com')`

#### Custom Types

To defined your own type `#type` method can be used:

```ruby
# file: Envfile
type :json do |raw_string|
  JSON.parse(raw_string)
end

variable :CUSTOM_OPTIONS, :json
```

> NOTE: It is important to define any custom type before their usage. Otherwise you will get an `ArgumentError` exception.

### Groups

Groups give you more flexibility to define when variables are needed.
It's similar to groups in a Gemfile:

```ruby
# file: Envfile
variable :FORCE_SSL, :boolean, default: 'false'

group :production do
  variable :SECRET_KEY_BASE
end

group :development, :staging do
  variable :DEV_KEY
end
```

```ruby
# For local development you would typically do:
ENVied.require(:default) #=> Only ENV['FORCE_SSL'] is required
# On the production server:
ENVied.require(:default, :production) #=> ...also ENV['SECRET_KEY_BASE'] is required

# You can also pass it a string with the groups separated by comma's:
ENVied.require('default, production')

# This allows for easily requiring groups using the ENV:
ENVied.require(ENV['ENVIED_GROUPS'])
# ...then from the prompt:
$ ENVIED_GROUPS='default,production' bin/rails server

# BTW the following are equivalent:
ENVied.require
ENVied.require(:default)
ENVied.require('default')
ENVied.require(nil)
```

### Defaults

In order to let other developers easily bootstrap the application, you can assign defaults to variables.
Defaults can be a value or a `Proc` (see example below).

Note that 'easily bootstrap' is quite the opposite of 'fail-fast when not all ENV-variables are present'. Therefore you should explicitly state when defaults are allowed:

```ruby
# Envfile
enable_defaults! { ENV['RACK_ENV'] == 'development' }

variable :FORCE_SSL, :boolean, default: 'false'
variable :PORT, :integer, default: proc {|envied| envied.FORCE_SSL ? 443 : 80 }
```

Please remember that ENVied only **reads** from ENV; it doesn't mutate ENV.
Don't let setting a default for, say `RAILS_ENV`, give you the impression that `ENV['RAILS_ENV']` is set.
As a rule of thumb you should only use defaults:
* for local development
* for ENV-variables that are solely used by your application (i.e. for `ENV['STAFF_EMAILS']`, not for `ENV['RAILS_ENV']`)

### More examples

* See the [examples](/examples)-folder for a more extensive Envfile
* See [the Envfile](https://github.com/eval/bunny_drain/blob/c54d7d977afb5e23a92da7a2fd0d39f6a7e29bf1/Envfile) for the bunny_drain application

## Command-line interface

For help on a specific command, use `envied help <command>`.

```bash
$ envied help
Commands:
  envied check                   # Checks whether you environment contains required variables
  envied check:heroku            # Checks whether a Heroku config contains required variables
  envied check:heroku:binstub    # Generates a shell script for the check:heroku-task
  envied extract                 # Grep code to find ENV-variables
  envied help [COMMAND]          # Describe available commands or one specific command
  envied init                    # Generates a default Envfile in the current working directory
  envied init:rails              # Generate all files needed for a Rails project
  envied version, --version, -v  # Shows version number
```

## How do I

### ...find all ENV-variables my app is currently using?

```
$ bundle exec envied extract
```

This comes in handy when you're not using ENVied yet. It will find all `ENV['KEY']` and `ENV.fetch('KEY')` statements in your project.

It assumes a standard project layout (see the default value for the globs-option).

### ...check the config of a Heroku app?

The easiest/quickest is to run:

```
$ heroku config --json | bundle exec envied check:heroku
```

This is equivalent to having the heroku config as your local environment and running `envied check:heroku --groups default production`.

You want to run this right before a deploy to Heroku. This prevents that your app will crash during bootup because ENV-variables are missing from heroku config.

You can turn the above into a handy binstub like so:
```
$ bundle exec envied check:heroku:binstub
# created bin/heroku-env-check
```

This way you can do stuff like:
```
$ ./bin/heroku-env-check && git push live master
```

## Testing

```bash
bundle install
bundle exec rspec
```

## Developing

```bash
bundle exec pry --gem
```

## Contributing

1. Fork it: http://github.com/eval/envied/fork
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Create a new pull request for your feature branch
