# ENVied [![pipeline status](https://gitlab.com/envied/envied/badges/master/pipeline.svg)](https://gitlab.com/envied/envied/commits/master) [![project chat](https://img.shields.io/badge/zulip-join_chat-brightgreen.svg)](https://envied-rb.zulipchat.com/)

_Canonical Repository:_ https://gitlab.com/envied/envied/tree/master#envied

### TL;DR ensure presence and type of your app's ENV-variables.

For the rationale behind this project, see this [blogpost](https://www.gertgoet.com/2014/10/14/envied-or-how-i-stopped-worrying-about-ruby-s-env.html).

## Features

* check for presence and correctness of ENV-variables
* access to typed ENV-variables (integers, booleans etc. instead of just strings)
* check the presence and correctness of a Heroku config

## Non-features

* provide or load ENV-values

## Contents

* [Quickstart](#quickstart)
* [Installation](#installation)
* [Configuration](#configuration)
  * [Types](#types)
  * [Key alias](#key-alias-unreleased)
    * [env-type](#env-type-unreleased)
  * [Groups](#groups)
* [Command-line interface](#command-line-interface)
* [Best Practices](#best-practices)
* [FAQ](#faq)
* [Testing](#testing)
* [Development](#development)
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
* one of `ENV['FORCE_SSL']`, `ENV['PORT']` is absent.
* or: their values *cannot* be coerced (resp. to boolean and integer).

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

* `:array` (e.g. 'tag1,tag2' becomes `['tag1', 'tag2']`)
* `:boolean` (e.g. '0'/'1', 'f'/'t', 'false'/'true', 'off'/'on', 'no'/'yes' for resp. false and true)
* `:date` (e.g. '2014-3-26')
* `:env` (similar to `:string`, but accessible via ENV - see [Key alias](#key-alias-unreleased) for details)
* `:float`
* `:hash` (e.g. 'a=1&b=2' becomes `{'a' => '1', 'b' => '2'}`)
* `:integer`
* `:string` (implied)
* `:symbol`
* `:time` (e.g. '14:00')
* `:uri` (e.g. 'http://www.google.com' becomes result of `URI.parse('http://www.google.com')`)


### Key alias (unreleased)

By default the value for variable `FOO` should be provided by `ENV['FOO']`. Sometimes though it's convenient to let a different key provide the value, based on some runtime condition. A key-alias will let you do this.  

Consider for example local development where `REDIS_URL` differs between the development and test environment. Normally you'd prepare different shells with different values for `REDIS_URL`: one shell you can run tests in, and other shells where you'd run the console/server etc. This is cumbersome and easy to get wrong.

With a key alias that's calculated at runtime (e.g. `Rails.env`) you'd set values for both `REDIS_URL_TEST` and `REDIS_URL_DEVELOPMENT` and the right value will be used for test and development.

Full example:
```
# file: Envfile
key_alias! { Rails.env }

variable :REDIS_URL, :uri
```

Source the following in your environment:
```
# file: .envrc
export REDIS_URL_DEVELOPMENT=redis://localhost:6379/0
export REDIS_URL_TEST=redis://localhost:6379/1
```
Now commands like `rails console` and `rails test` automatically point to the right redis database.

Note that `ENV['REDIS_URL']` is still considered but `REDIS_URL_<key_alias>` takes precedence.  
Also: any truthy value provided as key_alias is converted to an upcased string.  
Finally: this setting is optional.


#### env-type (unreleased)

Variables of type `:env` take the key alias into account when accessing `ENV['FOO']`.

Say, your application uses `ENV['DATABASE_URL']` (wich you can't change to `ENVied.DATABASE_URL`). Normally this would mean that the key alias has no effect. For env-type variables however, the key alias is taken into account:

```
# file: Envfile

key_alias! { Rails.env }

variable :DATABASE_URL, :env
```

The following now works:
```shell
$ DATABASE_URL_DEVELOPMENT=postgres://localhost/blog_development rails runner "p ENV['DATABASE_URL']"
"postgres://localhost/blog_development"
```

Note: this also works for `ENV.fetch('FOO')`.  
Also: no coercion is done (like you would expect when accessing ENV-values directly).  

This means that for Rails applications when you set values for `DATABASE_URL_DEVELOPMENT` and `DATABASE_URL_TEST`, you no longer need a `config/database.yml`.


### Groups

Groups give you more flexibility to define when variables are needed.
It's similar to groups in a Gemfile:

```ruby
# file: Envfile
variable :FORCE_SSL, :boolean

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

## Best Practices

Some best practices when using ENVied or working with env-configurable applications in general.

### include a .envrc.sample

While ENVied will warn you when you start an application that is 'under-configured', it won't tell users what good default values are. To solve this add a file to the root of your project that contains sane defaults and instructions:
```
# file: .envrc.sample
# copy this file to .envrc and adjust values if needed
# then do `source .envrc` to load

export DATABASE_URL=postgres://localhost/blog_development
# export FORCE_SSL=true # only needed for production

# you can find this token on the Heroku-dashboard
export DEPLOY_TOKEN=1234-ABC-5678
```

### let [direnv](https://direnv.net/) manage your environment

[direnv](https://direnv.net/) will auto-(un)load values from `.envrc` when you switch folders.  

As a bonus it has some powerful commands in it's [stdlib](https://direnv.net/#man/direnv-stdlib.1).  
For example:
```
# this adds the project's bin-folder to $PATH
PATH_add bin
# so instead of `./bin/rails -h` you can do `rails -h` from anywhere (deep) in the project

# the following will use the .envrc.sample as a basis
# when new variables are introduced upstream, you'll automatically use these defaults
if [ -f .envrc.sample ]; then
  source_env .envrc.sample
fi
...your overrides

# a variant of this is source_up
# an .envrc in a subfolder can load the .envrc from the root of the project and override specific values
# this would allow e.g. for a specific test-environment in the subfolder:
# in my-project/test/.envrc
source_up .envrc
export DATABASE_URL=the-test-db-url
```


## FAQ

### How to find all ENV-variables my app is currently using?

```
$ bundle exec envied extract
```

This comes in handy when you're not using ENVied yet. It will find all `ENV['KEY']` and `ENV.fetch('KEY')` statements in your project.

It assumes a standard project layout (see the default value for the globs-option).

### How to check the config of a Heroku app?

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

### What happened to default values??

The short version: simplicity, i.e. the best tool for the job.  

In the early days of ENVied it was possible to provide default values for a variable.  
While convenient, it had several drawbacks:
- it would introduce a value for ENVied.FOO, while ENV['FOO'] was nil: confusing and a potential source of bugs.
- it hides the fact that an application can actually be configged via the environment.
- it creates an in-process environment which is hard to inspect (as opposed to doing `printenv FOO` in a shell, after or before starting the application).
- there are better ways: e.g. a sample file in a project with a bunch of exports (ie `export FOO=sane-default # and even some documentation`) that someone can source in their shell (see [Best Practices](#best-practices)).
- made the code quite complex.

As an alternative include a file `.envrc.sample` in the root of your project containing default values (ie `export FOO=bar`) that users can source in their shell. See also [Best Practices](#best-practices).


## Development

```bash
$ ./bin/setup

# run tests
$ ./bin/rspec

# hack with pry
$ ./bin/console

# run CLI:
$ ./bin/envied
```

There's a `.envrc.sample` included that can be used in combination with [direnv](http://direnv.net/).

## Contributing

To suggest a new feature, [open an Issue](https://gitlab.com/envied/envied/issues/new) before opening a PR.

1. Fork it: https://gitlab.com/envied/envied/-/forks/new
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Create a new pull request for your feature branch
