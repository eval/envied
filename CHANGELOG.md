# 0.6.2 / 2014-08-20

* Add `envied check:heroku` to do a check on your Heroku app.

* Add `envied check:heroku:binstub` to generate script for convenient 'check:heroku'

# 0.6.1 / 2014-08-13

* Add `envied check` to check whether defined variables are present and valid.

# 0.6.0 / 2014-08-13

* The configuration now lives in `Envfile` by default.

# 0.5.0 / 2014-07-02

* add Array Hash types

  ```ruby
  # in env.rb
  ENVied.configure { variable :TAGS, :Array; variable :HASH, :Hash }
  ENVied.require

  $ HASH=a=1&b=2 TAGS=tag1,tag2 ruby -renvied -r./env.rb -e 'p ENVied.TAGS'
  # ["tag1", "tag2"]
  $ HASH='a=1&b=2' TAGS=tag1,tag2 ruby -renvied -r./env.rb -e 'p ENVied.HASH'
  # {'a' => '1', 'b' => '2'}
  ```

# 0.4.0 / 2014-05-16

* groups added

  This allows for more fine-grained requiring.  
  See the section in the [README](https://github.com/eval/envied/tree/v0.4.0#groups).

* configuring is now simpler:

  ```ruby
  ENVied.configure { variable :RACK_ENV }
  # vs
  ENVied.configure {|env| env.variable :RACK_ENV }
  ```

* Deprecate `require!`. Use `require` instead.

  Just like requiring groups with Bundler.

* Deprecate lowercase methods for uppercase ENV-variables.

  `ENV['RACK_ENV']` is no longer accessible as `ENVied.rack_env`, only as `ENVied.RACK_ENV`.  
  This is not only what you would expect, but it also reduces the chance of clashing with existing class-methods.

# 0.3.0 / 2014-03-14

* defaults need to be enabled explicitly:

  `ENVied.configure(enable_defaults: Rails.env.development?) { ... }`

# 0.2.0 / 2014-03-14

* add defaults

# 0.1.0 / 2014-03-13

* add defaults
