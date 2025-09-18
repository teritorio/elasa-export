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
  set(:config, config)

  set(:download_cache, WebCache.new(life: '6h', dir: config['cache']))

  services = raw_config['services']
  default = services['__default__'] || {}
  set(:config, services.except('__default__').transform_values{ |project|
    project.transform_values{ |theme|
      theme.deep_merge(default)
    }
  })
end

get '/up' do
  204
end

get '/v0.1/:project/:theme/pois/favorites.pdf' do
  project = params['project']
  theme = params['theme']
  halt 401 if !settings.config[project] || !settings.config[project][theme]
  config = settings.config[project][theme]
  ids = params['ids']

  lang = request.env['HTTP_ACCEPT_LANGUAGE'] || 'en'
  lang = AcceptLanguage.parse(lang).match(*settings.config['langs']) || 'en'

  content_type :pdf
  Favorites.get_pdf(config, project, theme, ids, lang, settings.download_cache, settings.config['carbone_url'])
end
