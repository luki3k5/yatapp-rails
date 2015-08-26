require 'faraday'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'pry'

module Yatapp
  class YataApiCaller
    API_VERSION           = 'v1'
    API_END_POINT_URL     = "/api/:api_version/project/:project_id/:lang/:format"
    API_BASE_URL          = "http://api.yatapp.net"
    API_CALLER_ATTRIBUTES = [
      :connection,
      :languages,
      :project_id,
      :save_to_path,
      :translation_format
    ].freeze

    attr_accessor *Yatapp::Configuration::CONFIGURATION_OPTIONS
    attr_reader *API_CALLER_ATTRIBUTES

    def initialize
      initialize_configuration
      @translation_format = 'json'
      @save_to_path       = ""
      @connection         = prepare_connection
    end

    def set_languages(languages)
      @languages = languages
    end

    def set_project_id(project_id)
      @project_id = project_id
    end

    def set_save_to_path(path)
      @save_to_path = path
    end

    def set_translation_format(translation_format)
      @translation_format = translation_format
    end

    def get_translations
      languages.each do |lang|
        puts "Getting translation for #{lang}"
        api_url      = download_url(lang)
        api_response = connection.get(api_url)
        next if !should_save_the_translation?(api_response)
        save_translation(lang, api_response)
      end
    end

    private
      def should_save_the_translation?(api_response)
        if api_response.status != 200
          puts "INVALID RESPONSE: #{api_response.body}"
          return false
        end
        return true
      end

      def initialize_configuration
        options = Yatapp.options
        Configuration::CONFIGURATION_OPTIONS.each do |key|
          send("#{key}=", options[key])
        end
      end

      def prepare_connection
        Faraday.new(url: API_BASE_URL) do |faraday|
          faraday.adapter :typhoeus
        end
      end

      def save_translation(lang, response)
        bfp = save_file_path
        File.open("#{bfp}#{lang}.yata.#{translation_format}", 'wb') { |f| f.write(response.body) }
        puts "#{lang}.yata.#{translation_format} saved"
      end

      def save_file_path
        if defined?(Rails) && @save_to_path == ""
          "#{Rails.root}/config/locales/"
        elsif @save_to_path != ""
          @save_to_path
        end
      end

      def download_url(lang)
        url = API_END_POINT_URL.sub(':project_id', project_id)
        url = url.sub(':format', translation_format)
        url = url.sub(':api_version', API_VERSION)
        url = url.sub(':lang', lang)
        url = url + "?apiToken=#{api_access_token}"
      end

  end
end
