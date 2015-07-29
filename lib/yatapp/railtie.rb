require 'yatapp'
require 'rails'

module Yatapp
  class Railtie < Rails::Railtie
    railtie_name :yatapp

    rake_tasks do
      load "tasks/yata.rake"
    end
  end
end

