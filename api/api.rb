# typed: true
require 'sinatra'
require 'yaml'
require 'deep_merge'
require 'webcache'
require 'accept_language'

require './favorites'

configure do
  raw_config = YAML.load_file(ENV['CONFIG'])

  config = raw_config['config']
  set :config, config

  set :download_cache, WebCache.new(life: '6h', dir: config['cache'])

  services = raw_config['services']
  default = services['__default__'] || {}
  set :config_by_key, services.filter{ |id, _| id != '__default__' }.collect{ |id, config|
    config['id'] = id
    config = config.deep_merge(default)
    [config['key'], config]
  }.to_h
end


get '/favorites/:ids.pdf' do |ids|
  key = params['key']
  config = settings.config_by_key[key]
  halt 401 if !config

  lang = request.env['HTTP_ACCEPT_LANGUAGE'] || 'en'
  lang = AcceptLanguage.parse(lang).match(*settings.config['langs']) || 'en'

  content_type :pdf
  Favorites.get_pdf(config, ids, lang, settings.download_cache, settings.config['carbone_url'])
end
