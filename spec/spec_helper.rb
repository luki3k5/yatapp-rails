$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'yatapp'
require 'webmock/rspec'

Yatapp.configure do |c|
  c.api_access_token = 'TDIrT3ZEY3hPSHcvV3VlejNOK1owSk1OMmdtT1RIQ1Q3bUdOOXYxc0ZNcGttOEZFMHZ1eHpGdlBiblF3ZUwwanRMN0RtMFgwVHlndmVJQ1A3REhQbVE9PQ=='
  c.project_id = 'TEdYVzh2M0lKVWo0bUFrUzFOUlU5d1I5Z2ZVRXF6NWJwalNvT1hWanRrdz0='
  c.languages  = ['en', 'en_US']
  c.translation_format = 'yml'
  c.root = true
  c.save_to_path = "spec/fixtures/"
  c.download_on_start = true
end
