class ENVied
  class EnvVarExtractor
    def self.defaults
      @defaults ||= begin
        {
          extensions: %w(ru thor rake rb yml ruby yaml erb builder markerb),
          dirs: %w(.)
        }
      end
    end

    def defaults
      self.class.defaults
    end

    def self.env_var_re
      @env_var_re ||= begin
        /^[^\#]*        # not matching comments
          ENV
          (?:           # non-capture...
            \[. |       # either ENV['
            \.fetch\(.  # or ENV.fetch('
          )
          ([a-zA-Z_]+)  # capture variable name
        /x
      end
    end

    attr_reader :dirs, :extensions

    def initialize(options = {})
      @dirs = options.fetch(:dirs, self.defaults[:dirs])
      @extensions = options.fetch(:extensions, self.defaults[:extensions])
    end

    def self.extract_from(dirs, options = {})
      new(options.merge(dirs: Array(dirs))).extract
    end


    # Extract all keys recursively from ENV used in the code in `dirs`.
    # Any occurence of `ENV['A']` or `ENV.fetch('A')` in code (not in comments), will result
    # in 'A' being extracted.
    #
    # @param dirs [Array<String>] the collection of folders to go through
    #
    # @example
    #   EnvVarExtractor.extract_from(*%w(app lib))
    #   # => {'A' => [{:path => 'app/models/user.rb', :line => 2}],
    #         'B' => [{:path => 'config/application.rb', :line => 12}]}
    #
    # @return [<Hash{String => Array<String => Array>}>] the list of items.
    def extract(dirs = self.dirs)
      results = Hash.new { |hash, key| hash[key] = [] }

      Array(dirs).each do |dir|
        Dir.glob(dir).each do |item|
          next if File.basename(item)[0] == ?.

          if File.directory?(item)
            results.merge!(extract("#{item}/*"))
          else
            next unless extensions.detect {|ext| File.extname(item)[ext] }
            File.readlines(item).each_with_index do |line, ix|
              if variable = line[self.class.env_var_re, 1]
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
