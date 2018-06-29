require "yatapp/version"
require "yatapp/configuration"
require "yatapp/yata_api_caller"
require 'yatapp/railtie' if defined?(Rails)
require "yatapp/inbox.rb"
require "yatapp/socket.rb"

module Yatapp
  extend Configuration

  class << self
    def get_translations
      api_caller.get_translations
    end

    def download_translations
      api_caller.download_translations
    end

    def start_websocket
      Phoenix::Socket.new unless File.basename($0) == 'rake'
    end

    def api_caller
      @api_caller ||= YataApiCaller.new
    end
  end
end
