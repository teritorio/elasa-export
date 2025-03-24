require 'mime-types'
require 'base64'
require 'cgi'
require 'httparty'

class Favorites
  def self.get_pdf(config, project, theme, ids, lang, cache, carbone_url)
    config_fav = config['templates']['favorites']
    api_url = config['api_url']
    favorites = api_favorites(cache, "#{api_url}/#{project}/#{theme}/pois.geojson?ids=#{ids}&as_point=true&short_description=true")

    favorites = if favorites
      favorites['features'].collect{ |feature|
        p = feature['properties']

        p['phones'] = p['phone'].join(', ') if p['phone']
        p['address'] = [
          p['addr:housenumber'],
          p['addr:street'],
          p['addr:postcode'],
          p['addr:city'],
        ].compact.join(' ')

        p['website'] = p['website']&.collect{ |url| CGI.escapeHTML(url) }

        feature
      }
    end

    qr_shortener_url = config['services']['qr_shortener_url']
    url_to_encode = CGI.escape(config_fav['qrcode_callback_url'] + ids)
    shortener_url = "#{qr_shortener_url}/shorten?url=#{url_to_encode}"
    favorites_qrcode_url = "#{qr_shortener_url}/qrcode.svg?url=#{url_to_encode}"

    globals = {
      'favorites_short_url' => cache.get(shortener_url).content,
      'favorites_qrcode_url' => favorites_qrcode_url,
    }

    data = {
      'settings' => api_settings(cache, "#{config['api_url']}/#{project}/#{theme}/settings.json"),
      'favorites' => favorites,
      'globals' => globals,
    }

    body = {
      data: data,
      options: {
        convertTo: 'pdf',
        lang: lang,
      },
      images: config_fav['images'].collect{ |image|
        image_url = data.dig(*image['property'])
        prepare_image(image, get_image(cache, image_url)) if image_url
      }.compact,
    }

    path = config_fav['path']
    url = "#{carbone_url}/render/#{path}"
    r = HTTParty.post(url, body: body.to_json, headers: { 'Content-Type' => 'application/json' })
    r.body if r.code == 200
  end

  def self.prepare_image(config, image_data)
    mime_type = MIME::Types.type_for(config['zipPath'].split('.')[-1])
    {
      path: config['zipPath'],
      content: encode_image(
        mime_type,
        image_data,
      ),
    }
  end

  def self.api_settings(cache, url)
    JSON.parse(cache.get(url).content)
  end

  def self.api_favorites(cache, url)
    JSON.parse(cache.get(url).content)
  end

  def self.get_image(cache, url)
    cache.get(url).content
  end

  def self.encode_image(mime_type, data)
    "data:#{mime_type};base64,#{Base64.encode64(data)}"
  end
end
