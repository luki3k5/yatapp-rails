require 'faraday'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'pry'

module Yatapp
  class YataApiCaller
    attr_reader :project_hash, :is_rails

    API_END_POINT_URL = "/api/project/:project_id/download/:lang"
    API_BASE_URL = "http://yata-staging.herokuapp.com"

    def initialize(project_hash)
      @connection   = make_connection
      @project_hash = project_hash
      @is_rails     = defined?(Rails)
    end

    def make_connection
      Faraday.new(url: API_BASE_URL) do |faraday|
        faraday.adapter :typhoeus
      end
    end

    def get_translations(languages)
      languages.each do |lang|
        url = download_url(lang)
        api_response = @connection.get(url)
        save_translation(lang, api_response)
      end
    end

    private
      def save_translation(lang, response)
        bfp = base_file_path
        File.open("#{bfp}#{lang}.yata.yml", 'wb') { |f| f.write(response.body) }
      end

      def base_file_path
        "#{Rails.root}/config/locales/" if is_rails
      end

      def download_url(lang)
        url = API_END_POINT_URL.sub(':project_id', project_hash)
        url = url.sub(':lang', lang)
      end

  end
end
