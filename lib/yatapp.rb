require "yatapp/version"
require "yatapp/configuration"
require "yatapp/yata_api_caller"
require 'yatapp/railtie' if defined?(Rails)

module Yatapp
  extend Configuration

  class << self

  end
end
