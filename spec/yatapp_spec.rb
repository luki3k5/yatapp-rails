require 'spec_helper'

describe Yatapp do
  it 'has a version number' do
    expect(Yatapp::VERSION).not_to be nil
  end

  it '#get_translations' do
    response_en = File.open('spec/fixtures/en_stub.yml')
    stub_request(:get, /(?=.*\brun.yatapp.net\b)(?=.*\ben).*$/).with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(status: 200, body: response_en, headers: {})

    response_en_US = File.open('spec/fixtures/en_US_stub.yml')
    stub_request(:get, /(?=.*\brun.yatapp.net\b)(?=.*\ben_US).*$/).with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(status: 200, body: response_en_US, headers: {})

    Yatapp.get_translations

    expect File.open('spec/fixtures/en.yml') == File.open('spec/fixtures/en_stub.yml')
    expect File.open('spec/fixtures/en_US.yml') == File.open('spec/fixtures/en_US_stub.yml')
  end

  it '#download_translations' do
    expect I18n.available_locales == [:en]

    response_en = File.open('spec/fixtures/en_stub.json')
    stub_request(:get, /(?=.*\brun.yatapp.net\b)(?=.*\ben).*$/).with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(status: 200, body: response_en, headers: {})

    response_en_US = File.open('spec/fixtures/en_US_stub.json')
    stub_request(:get, /(?=.*\brun.yatapp.net\b)(?=.*\ben_US).*$/).with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(status: 200, body: response_en_US, headers: {})

    Yatapp.download_translations

    expect I18n.locale == :en
    expect I18n.available_locales == [:en, :en_US]
    expect I18n.t('hello') == 'Hello world'

    I18n.locale = :en_US
    expect I18n.t('hello') == 'Hi world'
  end

  it 'connects to websocket' do
    WebMock.allow_net_connect!
    Phoenix::Socket.new
  end
end
