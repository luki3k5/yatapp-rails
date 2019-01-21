$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'yatapp'
require 'webmock/rspec'

Yatapp.configure do |c|
  c.api_access_token = 'ZEQ1TUoxUTBjL1V4R0VXWjFTeGtWaWc2WGNhbWkwWXlCSVBhUGVkemozUmlsZmdyVnhFOTlJZkMvdWxJSkRUd1RxY0ZUaitCYklOaW5rMUJ6YlhZTUE9PQ=='
  c.project_id = '56'
  c.languages  = ['en', 'en_US']
  c.translation_format = 'yml'
  c.root = true
  c.save_to_path = "spec/fixtures/"
  c.download_on_start = true
end
