# ENVied

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
`{'FORCE_SSL' => 'true', 'PORT' => '3000'}`.

A meaningful error will in this case explain what key and type is needed.

### 3) Use typed variables

Variables accessed via ENVied have the configured type:

```ruby
ENVied.port => 1
ENVied.force_ssl => false
```

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
