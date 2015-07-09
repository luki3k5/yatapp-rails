require 'faraday'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'pry'

module Yatapp
  class YataApiCaller
    API_CALLER_ATTRIBUTES = [:connection].freeze
    API_END_POINT_URL     = "/api/project/:project_id/download/:lang"
    API_BASE_URL          = "http://api.yatapp.net"

    attr_accessor *Yatapp::Configuration::CONFIGURATION_OPTIONS
    attr_reader *API_CALLER_ATTRIBUTES

    def initialize
      initialize_configuration
      @connection = make_connection
    end

    def make_connection
      Faraday.new(url: API_BASE_URL) do |faraday|
        faraday.adapter :typhoeus
      end
    end

    def get_translations
      languages.each do |lang|
        api_url      = download_url(lang)
        api_response = connection.get(api_url)
        save_translation(lang, api_response)
      end
    end

    private
      def initialize_configuration
        options = Yatapp.options
        Configuration::CONFIGURATION_OPTIONS.each do |key|
          send("#{key}=", options[key])
        end
      end

      def save_translation(lang, response)
        bfp = base_file_path
        File.open("#{bfp}#{lang}.yata.yml", 'wb') { |f| f.write(response.body) }
      end

      def base_file_path
        "#{Rails.root}/config/locales/" if defined?(Rails)
      end

      def download_url(lang)
        url = API_END_POINT_URL.sub(':project_id', project)
        url = url.sub(':lang', lang)
      end

  end
end
