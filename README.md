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

## Usage in Rails
Before using Yata integration gem you need to configure it.
We recommend adding the following lines to freshly created initialiser
in your rails project:


```ruby

include Yatapp

Yatapp.configure do |c|
  c.api_access_token = ENV['YATA_API_KEY'] # access key to Yata
  c.project_id 'your-project-id' # project id you wish to fetch from (you can find it under settings of your organization)
  c.languages  ['en', 'de']      # add any languages you wish by language code - default ['en']
  c.translations_format 'json'   # format you wish to get files in, available for now are (yaml, js, json, properties, xml, strings and plist) - default 'json'
  c.save_to_path "app/assets/javascripts/" # default /config/locales/
  c.root # add locale root to file with translations - default false
end
```


Add this line to configuration if you want websocket integration.

``` ruby
include Yatapp

Yatapp.configure do |c|
  c.api_access_token = ENV['YATA_API_KEY']
  ...
end

Yatapp.start_websocket

```

Websocket integration connects to Yata server and stays open. All changes in translations are auto-fetched to the app.

When app connects to the Yata server for the first time it downloads all translation and saves them to the i18n store. Then all actions on translations like create, update and delete are broadcasting information and i18n store is updated.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/yatapp/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
