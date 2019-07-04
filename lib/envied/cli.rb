require 'thor'
require 'json'
require 'envied/env_var_extractor'

class ENVied
  class Cli < Thor
    include Thor::Actions
    source_root File.expand_path('../templates', __FILE__)

    desc "version, --version, -v", "Shows version number"
    def version
      puts ENVied::VERSION
    end
    map %w(-v --version) => :version

    desc "extract", "Grep code to find ENV-variables"
    long_desc <<-LONG
      Greps source-files to find all ENV-variables your code is using.

      This task helps you find variables to put in your Envfile.

      By default the test/spec-folders are excluded. Use `--tests` to include them.
    LONG
    option :globs, type: :array, default: ENVied::EnvVarExtractor.defaults[:globs], banner: "*.* lib/*"
    option :tests, type: :boolean, default: false, desc: "include tests/specs"
    def extract
      globs = options[:globs]
      globs << "{test,spec}/*" if options[:tests]
      var_occurrences = ENVied::EnvVarExtractor.new(globs: globs).extract

      puts "Found %d occurrences of %d variables:" % [var_occurrences.values.flatten.size, var_occurrences.size]
      var_occurrences.sort.each do |var, occs|
        puts var
        occs.sort_by{|i| i[:path].size }.each do |occ|
          puts "* %s:%s" % occ.values_at(:path, :line)
        end
        puts
      end
    end

    desc "init", "Generates a default Envfile in the current working directory"
    def init
      puts "Writing Envfile to #{File.expand_path('Envfile')}"
      template("Envfile.tt")

      puts "Add the following snippet (or similar) to your app's initialization:"
      puts "ENVied.require(*ENV['ENVIED_GROUPS'] || [:default, ENV['RACK_ENV']])"
    end

    desc "init:rails", "Generate all files needed for a Rails project"
    define_method "init:rails" do
      puts "Writing Envfile to #{File.expand_path('Envfile')}"
      template("Envfile.tt")
      inject_into_file "config/application.rb", "\nENVied.require(*ENV['ENVIED_GROUPS'] || Rails.groups)", after: /^ *Bundler.require.+$/
      legacy_initializer = Dir['config/initializers/*envied*.rb'].first
      if legacy_initializer && File.exists?(legacy_initializer)
        puts "Removing 'ENVied.require' from #{legacy_initializer.inspect}."
        puts "(you might want to remove the whole file)"
        comment_lines legacy_initializer, /ENVied.require/
      end
    end

    desc "check", "Checks whether you environment contains required variables"
    long_desc <<-LONG
      Checks whether required variables are present and valid in your shell.

      On success the process will exit with status 0.
      Else the missing/invalid variables will be shown, and the process will exit with status 1.
    LONG
    option :groups, type: :array, desc: "uses ENV['ENVIED_GROUPS'] as default if present", default: ENV['ENVIED_GROUPS'] || %w(default), banner: 'default production'
    option :quiet, type: :boolean, desc: 'Communicate success of the check only via the exit status.'
    def check
      if rails_project?
        require File.expand_path 'config/environment.rb'
      end
      ENVied.require(*options[:groups])
      unless options[:quiet]
        puts "All variables for group(s) #{options[:groups]} are present and valid"
      end
    end

    desc "check:heroku", "Checks whether a Heroku config contains required variables"
    long_desc <<-LONG
      Checks the config of your Heroku app against the local Envfile.

      The Heroku config should be piped to this task:

      heroku config --json | bundle exec envied check:heroku

      Use the check:heroku:binstub-task to turn this into a bash-script.

      On success the process will exit with status 0.
      Else the missing/invalid variables will be shown, and the process will exit with status 1.
    LONG
    option :groups, type: :array, default: %w(default production), banner: 'default production'
    option :quiet, type: :boolean, desc: 'Communicate success of the check only via the exit status.'
    define_method "check:heroku" do
      if STDIN.tty?
        error "Please pipe to this task i.e. `heroku config --json | bundle exec envied check:heroku`"
        exit 1
      end
      heroku_env = JSON.parse(STDIN.read)
      ENV.replace(heroku_env)

      requested_groups = ENV['ENVIED_GROUPS'] || options[:groups]
      ENVied.require(*requested_groups)
      unless options[:quiet]
        puts "All variables for group(s) #{requested_groups} are present and valid in your Heroku app"
      end
    end

    desc "check:heroku:binstub", "Generates a shell script for the check:heroku-task"
    long_desc <<-LONG
      Generates a shell script to check the Heroku config against the local Envfile.

      The same as the check:heroku-task, but all in one script (no need to pipe `heroku config --json` to it etc.).
    LONG
    option :dest, banner: "where to put the script", desc: "Default: bin/<app>-env-check or bin/heroku-env-check"
    option :app, banner: "name of Heroku app", desc: "uses ENV['HEROKU_APP'] as default if present", default: ENV['HEROKU_APP']
    option :groups, type: :array, default: %w(default production), banner: 'default production'
    define_method "check:heroku:binstub" do
      require 'fileutils'
      @app = options[:app]
      @dest = options[:dest]
      @dest ||= File.join(*%W(bin #{(@app || 'heroku')}-env-check))
      @groups = options[:groups]

      full_dest = File.expand_path(@dest)
      template("heroku-env-check.tt", full_dest)
      FileUtils.chmod 0755, full_dest
    end

    no_tasks do
      def rails_project?
        File.exists?('config/environment.rb')
      end
    end
  end
end
