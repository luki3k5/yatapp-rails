require "yatapp/version"
require "yatapp/configuration"
require "yatapp/yata_api_caller"
require 'yatapp/railtie' if defined?(Rails)
require "yatapp/inbox.rb"
require "yatapp/socket.rb"

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

    def all_projects
      @all_projects ||= []
    end

    def all_projects_add(project)
      @all_projects ||= []
      @all_projects << project
    end
  end

  module Methods
    def yata_project
      @current_project = YataApiCaller.new
      yield
      Yatapp.all_projects_add(@current_project)
    end

    def languages(languages)
      @current_project.set_languages(languages)
    end

    def save_to_path(path)
      @current_project.set_save_to_path(path)
    end

    def project_id(project_id)
      @current_project.set_project_id(project_id)
    end

    def translations_format(frmt)
      @current_project.set_translation_format(frmt)
    end

    def get_translations
      Yatapp.all_projects.map { |p| p.get_translations }
    end

    def download_translations
      Yatapp.all_projects.map { |p| p.download_translations }
    end
  end
end
