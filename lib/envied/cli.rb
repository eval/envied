require 'thor'

class ENVied
  class Cli < Thor
    include Thor::Actions
    source_root File.expand_path('../templates', __FILE__)

    desc "init", "Generate a default Envfile in the current working directory."
    def init
      puts "Writing new Envfile to #{File.expand_path('Envfile')}"
      template("Envfile.tt")
    end
  end
end
