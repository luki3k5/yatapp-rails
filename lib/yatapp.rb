require "yatapp/version"
require "yatapp/configuration"
require "yatapp/yata_api_caller"
require 'yatapp/railtie' if defined?(Rails)

module Yatapp
  extend Configuration

  class << self
    def included(includer)
      includer.send(:include, Methods)
      includer.extend(Methods)
    end

    def api_caller
      @api_caller ||= YataApiCaller.new
    end

  end

  module Methods
    def get_translations
      Yatapp.api_caller.get_translations
    end
  end
end
