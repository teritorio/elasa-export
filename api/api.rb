# typed: true
require 'sinatra'
require 'yaml'
require 'deep_merge'
require 'webcache'
require 'accept_language'

require './favorites'

api_url = ENV['API_URL'] || raise('API_URL env variable is required')

configure do
  set(:config, ['CARBONE_URL', 'CACHE', 'API_URL', 'QR_SHORTENER_URL', 'LANGS'].to_h{ |key|
    [
      key.downcase,
      ENV[key] || raise("#{key} env variable is required")
    ]
  })
  settings.config['langs'] = settings.config['langs'].split(',')

  set(:download_api_cache, WebCache.new(life: '3m', dir: settings.config['cache']))
  set(:download_poi_cache, WebCache.new(life: '6h', dir: settings.config['cache']))

  config = YAML.load_file(ENV['CONFIG'])
  set(:config, config || {})
end

get '/up' do
  204
end

get '/v0.1/:project/:theme/pois/favorites.pdf' do
  project_slug = params['project']
  theme_slug = params['theme']
  config = settings.config
  ids = params['ids']

  lang = request.env['HTTP_ACCEPT_LANGUAGE'] || 'en'
  lang = AcceptLanguage.parse(lang).match(*settings.config['langs']) || 'en'

  projects = JSON.parse(settings.download_api_cache.get(api_url).content)
  project = projects[project_slug]
  halt 404 if project.nil? || project['themes'][theme_slug].nil?
  project['themes'] = [project['themes'][theme_slug]]
  site_url = project['themes'][0]['site_url']
  halt 404 if site_url.nil?

  site_utl_lang = site_url[lang] || site_url['en'] || site_url.values.first
  qrcode_callback_url = "#{site_utl_lang}/?origin=link_share#mode=favorites&favs="

  content_type :pdf
  Favorites.get_pdf(config, api_url, project_slug, theme_slug, project, ids, lang, qrcode_callback_url, settings.download_poi_cache, settings.config['carbone_url'], settings.config['qr_shortener_url'])
end
