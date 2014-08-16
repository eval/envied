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

    desc "check", "Checks whether all ENV-variables are present and valid"
    long_desc <<-LONG
      Checks whether all ENV-variables are present and valid.

      On success the process will exit with status 0.
      Else the missing/invalid variables will be shown, and the process will exit with status 1.
    LONG
    option :groups, type: :array, default: %w(default), banner: 'default production'
    def check
      ENVied.require(*options[:groups])
      puts "All ENV-variables for group(s) #{options[:groups]} are ok!"
    end
  end
end
