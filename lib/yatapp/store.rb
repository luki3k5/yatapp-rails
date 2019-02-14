begin
  require 'rails-i18n'
rescue
  puts "WARNING: Failed to require rails-i18n gem, websocket integration may fail."
end

module Yatapp
  class Store
    def self.store_translations(lang, api_response)
      unless I18n.available_locales.include?(lang.to_sym)
        add_new_locale(lang)
      end

      translations = api_response[lang]

      I18n.backend.store_translations(lang.to_sym, translations)
      puts "Loaded all #{lang} translations."
    end

    def self.add_new_key(key, values)
      values.each do |value|
        unless I18n.available_locales.include?(value['lang'].to_sym)
          add_new_locale(value['lang'])
        end

        key_array        = key.split(".")
        translation_hash = key_array.reverse.inject(value['text']) {|acc, n| {n => acc}}

        I18n.backend.store_translations(value['lang'].to_sym, translation_hash)
        puts "new translation added: #{value['lang']} => #{key}: #{value['text']}"
      end
    end

    private

    def self.add_new_locale(lang)
      existing_locales = I18n.config.available_locales
      new_locales      = existing_locales << lang.to_sym

      I18n.config.available_locales = new_locales.uniq
    end
  end
end
