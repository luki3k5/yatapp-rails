module Yatapp
  module Configuration
    CONFIGURATION_OPTIONS = [
      :languages,
      :api_access_token,
      :project
    ].freeze

    attr_accessor *CONFIGURATION_OPTIONS

    def configure
      yield self
    end

    def options
      CONFIGURATION_OPTIONS.inject({}) do |opt, key|
        opt.merge!(key => send(key))
      end
    end
  end
end
