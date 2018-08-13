# Yatapp

Welcome to Yata integration gem, this gem will allow you to easy get your translations from http://yatapp.net service.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'yatapp'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install yatapp

## Configuration

Gem can be used in two ways:
* integration through API
* websocket integration

### Configuration Parameters

* `api_access_token` - access key to Yata (Organizations Settings > Security > API token)
* `project_id` - project id you wish to fetch from (Organizations Settings > Security> Projects > Id)
* `languages` - supported locales, add any locale you wish. Default: `[:en]`
* `translation_format` - format you wish to get files in, available for now are (yaml, js, json, properties, xml, strings and plist). Default: `json`
* `save_to_path` - you can define where files should be saved. Default: `/config/locales/`
* `root` - add locale as root to file with translations. Default: `false`

First two parameters are required and the rest is optional.

Translations with root set to `false`:

```yaml
  # en.yml

  hello: Hello
  hello_name: Hello %{name}
```

Translations with root set to `true`:
```yaml
  # en.yml

  en:
    hello: Hello
    hello_name: Hello %{name}
```

### API Integration

Recommended configuration:

```ruby
# config/initializers/yatapp.rb

include Yatapp

Yatapp.configure do |c|
  c.api_access_token = ENV['YATA_API_KEY']
  c.project_id = ENV['YATA_PROJECT_ID']
  c.languages  = ['en', 'de', 'en_US']
  c.translation_format = 'json'
end
```

To save file in a different location from default or add a locale as a root, add to configuration two lines as in example below:

```ruby
  # config/initializers/yatapp.rb

  include Yatapp

  Yatapp.configure do |c|
    c.api_access_token = ENV['YATA_API_KEY']
    c.project_id = ENV['YATA_PROJECT_ID']
    c.languages  = ['en', 'de', 'en_US']
    c.translation_format = 'json'
    c.save_to_path = '/public/locales/'
    c.root = true
  end
```

From now on your translations will be saved in `/public/locales/` directory and translations will have locale as a root.


API integration allows you to download all translations using rake task:

```bash
$ rake yata:fetch_translations
```

### Websocket Integration

Websocket integration connects to Yata server and stays open. All changes in translations are auto-fetched to the app.

When app connects to the Yata server for the first time it downloads all translation and saves them to the i18n store. Then all actions on translations like create, update and delete are broadcasting information and i18n store is updated.

Add this line to configuration if you want to enable websocket integration.

``` ruby
# config/initializers/yatapp.rb

include Yatapp

Yatapp.configure do |c|
  c.api_access_token = ENV['YATA_API_KEY']
  c.project_id = ENV['YATA_PROJECT_ID']
  c.languages  = ['en', 'de', 'en_US']
end

Yatapp.start_websocket

```



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/yatapp/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
