require 'faraday'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'pry'

module Yatapp
  class YataApiCaller
    ALLOWED_FORMATS = %w(json yaml)
    API_VERSION           = 'v1'
    API_END_POINT_URL     = "/api/:api_version/project/:project_id/:lang/:format"
    API_BASE_URL          = "http://api.yatapp.net"
    API_CALLER_ATTRIBUTES = [
      :connection,
      :languages,
      :project_id,
      :translation_format
    ].freeze

    attr_accessor *Yatapp::Configuration::CONFIGURATION_OPTIONS
    attr_reader *API_CALLER_ATTRIBUTES

    def initialize
      initialize_configuration
      @translation_format = 'json'
      @connection         = make_connection
    end

    def set_languages(languages)
      @languages = languages
    end

    def set_project_id(project_id)
      @project_id = project_id
    end

    def set_translation_format(format)
      @translation_format = translation_format
    end

    def get_translations
      languages.each do |lang|
        puts "Getting translation for #{lang}"
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

      def make_connection
        Faraday.new(url: API_BASE_URL) do |faraday|
          faraday.adapter :typhoeus
        end
      end

      def save_translation(lang, response)
        bfp = base_file_path
        File.open("#{bfp}#{lang}.yata.#{translation_format}", 'wb') { |f| f.write(response.body) }
        puts "#{lang}.yata.#{translation_format} saved"
      end

      def base_file_path
        "#{Rails.root}/config/locales/" if defined?(Rails)
      end

      def download_url(lang)
        url = API_END_POINT_URL.sub(':project_id', project_id)
        url = url.sub(':format', translation_format)
        url = url.sub(':api_version', API_VERSION)
        url = url.sub(':lang', lang)
      end

  end
end
