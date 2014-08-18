require 'thor'

class ENVied
  class Cli < Thor
    include Thor::Actions
    source_root File.expand_path('../templates', __FILE__)

    desc "init", "Generates a default Envfile in the current working directory"
    def init
      puts "Writing new Envfile to #{File.expand_path('Envfile')}"
      template("Envfile.tt")
    end

    desc "check", "Checks whether defined variables are present and valid"
    long_desc <<-LONG
      Checks whether defined variables are present and valid.

      On success the process will exit with status 0.
      Else the missing/invalid variables will be shown, and the process will exit with status 1.
    LONG
    option :groups, type: :array, default: %w(default), banner: 'default production'
    def check
      ENVied.require(*options[:groups])
      puts "All variables for group(s) #{options[:groups]} are present and valid"
    end

    desc "check:heroku", "Checks your Heroku app for presence and validity of defined variables"

    long_desc <<-LONG
      Checks the config of your Heroku app for presence and validity of defined variables.

      On success the process will exit with status 0.
      Else the missing/invalid variables will be shown, and the process will exit with status 1.
    LONG
    option :groups, type: :array, default: %w(default production), banner: 'default production'
    define_method "check:heroku" do
      config = `exec heroku config`
      heroku_env = Hash[config.split("\n")[1..-1].each_with_object([]) do |i, res|
        res << i.split(":", 2).map(&:strip)
      end]
      ENV.replace({}).update(heroku_env)
      ENVied.require(*options[:groups])
      puts "All variables for group(s) #{options[:groups]} are present and valid in your Heroku app"
    end
  end
end
