require 'httparty'

module Yatapp
  class YataApiCaller
    API_VERSION           = 'v1'
    API_END_POINT_URL     = "/api/:api_version/project/:project_id/:lang/:format"
    API_BASE_URL          = "http://run.yatapp.net"

    attr_accessor *Yatapp::Configuration::CONFIGURATION_OPTIONS

    def initialize
      @translation_format = 'json'
      @save_to_path       = ""
      @root               = false
      @languages          = ['en']
      initialize_configuration
    end

    def get_translations
      languages.each do |lang|
        puts "Getting translation for #{lang}"
        api_url      = download_url(lang)
        api_response = HTTParty.get(api_url)
        next if !should_save_the_translation?(api_response)
        save_translation(lang, api_response)
      end
    end

    def download_translations
      languages.each do |lang|
        puts "Getting translation for #{lang}"
        api_url      = download_url_websocket(lang)
        puts api_url
        api_response = HTTParty.get(api_url)
        next if !should_save_the_translation?(api_response)
        add_new_key_to_i18n(lang, JSON.parse(api_response.body))
      end
    end

    private
      def should_save_the_translation?(api_response)
        if api_response.code != 200
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
        url = API_BASE_URL + API_END_POINT_URL
        url = url.sub(':project_id', project_id)
        url = url.sub(':format', translation_format)
        url = url.sub(':api_version', API_VERSION)
        url = url.sub(':lang', lang)
        url = url + "?apiToken=#{api_access_token}&root=#{root}"
      end

      def download_url_websocket(lang)
        url = API_BASE_URL + API_END_POINT_URL
        url = url.sub(':project_id', "23")
        url = url.sub(':format', 'json')
        url = url.sub(':api_version', API_VERSION)
        url = url.sub(':lang', lang)
        url = url + "?apiToken=#{api_access_token}&root=true"
      end

      def add_new_key_to_i18n(lang, api_response)
        unless I18n.available_locales.include?(lang.to_sym)
          add_new_locale(lang)
        end

        translations = api_response[lang]
        I18n.backend.store_translations(lang.to_sym, translations)
        puts "Loaded all #{lang} translations."
      end

      def add_new_locale(lang)
        existing_locales = I18n.config.available_locales
        new_locales      = existing_locales << lang.to_sym
        I18n.config.available_locales = new_locales.uniq
      end
  end
end
