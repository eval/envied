## unreleased

### Added

 * ENVied.require accepts string with groups, e.g. 'default,production'

    This way it's possible to easily require groups using the ENV:

        # config/initializers/envied.rb
        ENVied.require(*ENV['ENVIED_GROUPS'] || Rails.groups)

        $ ENVIED_GROUPS='default,production' bin/rails server

### Fixed

 * extract: Multiple variables on line are correctly captured.

### Deprecated

 * prefer downcased variable types: `variable :PORT, :integer`

### Removed

 * extract: test/spec-folder are no longer part of the default globs.

    Use the option `--tests` to include it:

        $ bundle exec envied extract --tests

## 0.7.2 / 2014-9-7

### Added

 * extract-task: see all ENV-variables used in your project.

        $ bin/envied extract
        Found 63 occurrences of 45 variables:
        BUNDLE_GEMFILE
        * config/boot.rb:4
        * config/boot.rb:6
        ...

 * version-task (i.e. bin/envied --version)

## 0.7.1 / 2014-08-29

 * Total refactor (TM).

 * Fix bug in Heroku binstub.

    It checked for group 'default,production' instead of 'default' and 'production'.

## 0.7.0 / 2014-08-24

 * Add init:rails-task for setup in Rails applications.

## 0.6.3 / 2014-08-22

 * Fix bug: 'false' was not a coercible value.

## 0.6.2 / 2014-08-20

 * Add `envied check:heroku` to do a check on your Heroku app.

 * Add `envied check:heroku:binstub` to generate script for convenient 'check:heroku'

## 0.6.1 / 2014-08-13

 * Add `envied check` to check whether defined variables are present and valid.

## 0.6.0 / 2014-08-13

 * The configuration now lives in `Envfile` by default.

## 0.5.0 / 2014-07-02

 * add Array Hash types

        # in env.rb
        ENVied.configure { variable :TAGS, :Array; variable :HASH, :Hash }
        ENVied.require

        $ HASH=a=1&b=2 TAGS=tag1,tag2 ruby -renvied -r./env.rb -e 'p ENVied.TAGS'
        # ["tag1", "tag2"]
        $ HASH='a=1&b=2' TAGS=tag1,tag2 ruby -renvied -r./env.rb -e 'p ENVied.HASH'
        # {'a' => '1', 'b' => '2'}

## 0.4.0 / 2014-05-16

 * groups added

    This allows for more fine-grained requiring.  
    See the section in the [README](https://github.com/eval/envied/tree/v0.4.0#groups).

 * configuring is now simpler:

        ENVied.configure { variable :RACK_ENV }
        # vs
        ENVied.configure {|env| env.variable :RACK_ENV }

 * Deprecate `require!`. Use `require` instead.

    Just like requiring groups with Bundler.

 * Deprecate lowercase methods for uppercase ENV-variables.

    `ENV['RACK_ENV']` is no longer accessible as `ENVied.rack_env`, only as `ENVied.RACK_ENV`.  
    This is not only what you would expect, but it also reduces the chance of clashing with existing class-methods.

## 0.3.0 / 2014-03-14

 * defaults need to be enabled explicitly:

    `ENVied.configure(enable_defaults: Rails.env.development?) { ... }`

## 0.2.0 / 2014-03-14

 * add defaults

## 0.1.0 / 2014-03-13

 * add defaults
