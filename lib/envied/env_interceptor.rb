class ENVied
  module EnvInterceptor
    def [](key)
      if @__envied_env_keys.include?(key)
        ENVied.public_send(key)
      else
        super
      end
    end

    def fetch(key, *args)
      if @__envied_env_keys.include?(key)
        ENVied.public_send(key)
      else
        super
      end
    end
  end
end
