class ENVied
  class EnvVarExtractor
    def self.defaults
      @defaults ||= begin
        {
          extensions: %w(ru thor rake rb yml ruby yaml erb builder markerb haml),
          globs: %w(*.* Thorfile Rakefile {app,config,db,lib,script}/*)
        }
      end
    end

    def defaults
      self.class.defaults
    end

    attr_reader :globs, :extensions

    def initialize(options = {})
      @globs = options.fetch(:globs, self.defaults[:globs])
      @extensions = options.fetch(:extensions, self.defaults[:extensions])
    end

    def self.extract_from(globs, options = {})
      new(options.merge(globs: Array(globs))).extract
    end

    # Greps all ENV-variables from a line of text.
    # Captures 'A' in lines like `ENV['A']`, but also `ENV.fetch('A')`.
    #
    # @param line [String] the line to grep
    #
    # @example
    #   extractor.new.capture_variables("config.force_ssl = ENV['FORCE_SSL']")
    #   # => ["FORCE_SSL"]
    #
    # @return [Array<String>] the names o
    def capture_variables(line)
      line.scan(/ENV(?:\[|\.fetch\()['"]([^'"]+)['"]/).flatten
    end

    # Extract all keys recursively from files found via `globs`.
    # Any occurrence of `ENV['A']` or `ENV.fetch('A')`, will result
    # in 'A' being extracted.
    #
    # @param globs [Array<String>] the collection of globs
    #
    # @example
    #   EnvVarExtractor.new.extract(*%w(app lib))
    #   # => {'A' => [{:path => 'app/models/user.rb', :line => 2}, {:path => ..., :line => ...}],
    #         'B' => [{:path => 'config/application.rb', :line => 12}]}
    #
    # @return [<Hash{String => Array<String => Array>}>] the list of items.
    def extract(globs = self.globs)
      results = Hash.new { |hash, key| hash[key] = [] }

      Array(globs).each do |glob|
        Dir.glob(glob).each do |item|
          next if File.basename(item)[0] == ?.

          if File.directory?(item)
            results.merge!(extract("#{item}/*"))
          else
            next unless extensions.detect {|ext| File.extname(item)[ext] }
            File.readlines(item).each_with_index do |line, ix|
              capture_variables(line).each do |variable|
                results[variable] << { :path => item, :line => ix.succ }
              end
            end
          end
        end
      end

      results
    end
  end
end
