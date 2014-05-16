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
