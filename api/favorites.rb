require 'mime-types'
require 'base64'
require 'httparty'

class Favorites
  def self.get_pdf(config, ids, lang, cache, carbone_url)
    api_url = config['api_url']
    favorites = api_favorites(cache, "#{api_url}pois?ids=#{ids}&as_point=true&short_description=true")

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

        feature
      }
    end

    data = {
      'settings' => api_settings(cache, config['api_url']),
      'favorites' => favorites,
    }

    body = {
      data: data,
      options: {
        convertTo: 'pdf',
        lang: lang,
      },
      images: config['templates']['favorites']['images'].collect{ |image|
        {
          path: image['zipPath'],
          content: encode_image(cache, data.dig(*image['property']))
        }
      },
    }

    path = config['templates']['favorites']['path']
    url = "#{carbone_url}/render/#{path}"
    r = HTTParty.post(url, body: body.to_json, headers: { 'Content-Type' => 'application/json' })
    r.body if r.code == 200
  end

  def self.api_settings(cache, url)
    JSON.parse(cache.get(url).content)
  end

  def self.api_favorites(cache, url)
    JSON.parse(cache.get(url).content)
  end

  def self.image(cache, url)
    cache.get(url).content
  end

  def self.encode_image(cache, image_url)
    ext = image_url.split('.')[-1]
    mime_type = MIME::Types.type_for(ext)
    "data:#{mime_type};base64,#{Base64.encode64(image(cache, image_url))}"
  end
end
