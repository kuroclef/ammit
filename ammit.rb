#!/usr/bin/ruby
# coding: utf-8
=begin
/**
 *  Ammit -- An automated tweet eraser.
 *  Copyright (C) 2015  Kazumi Moriya <kuroclef@gmail.com>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
=end

require "bundler/setup"
require "json"
require "oauth"
require "time"
require "yaml"

class TwitterClient
  def initialize consumer_key, consumer_secret, access_token, access_token_secret
    @@consumer ||= OAuth::Consumer.new(consumer_key, consumer_secret, site: "https://api.twitter.com")
    @client      = OAuth::AccessToken.new(@@consumer, access_token, access_token_secret)
  end

  def api method
    "https://api.twitter.com/1.1/#{method}.json?"
  end

  def get method, params = {}
    JSON.parse(@client.get("#{api(method)}#{URI.encode_www_form(params)}").body, symbolize_names: true)
  end

  def post method, params = {}
    @client.post("#{api(method)}", params)
  end

  def get_stream params = {}
    while true
      uri = URI.parse("https://userstream.twitter.com/1.1/user.json?#{URI.encode_www_form(params)}")

      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      https.start

      request = Net::HTTP::Get.new(uri.request_uri, "Accept-Encoding": "identity")
      request.oauth!(https, @@consumer, @client)

      https.request(request) { |response|
        buffer = ""
        response.read_body { |chunk|
          buffer << chunk
          while line = buffer[/.*(\r\n)+/m]
            buffer.slice!(line)
            yield JSON.parse(line, symbolize_names: true) rescue nil
          end
          sleep 0.1
        }
      }
      https.finish
    end
  end
end

class Ammit
  def initialize consumer_key, consumer_secret, access_token, access_token_secret
    @client = TwitterClient.new(consumer_key, consumer_secret, access_token, access_token_secret)
  end

  def wait
    while true
      if Time.now.to_i % 3600 != 0
        sleep 1
        next
      end
      delete_tweets
      sleep 3000
    end
  end

  def delete_tweets
    now = Time.now
    @client.get("statuses/user_timeline", count: 200).each { |object|
      next if now - Time.parse(object[:created_at]) < 86000
      @client.post("statuses/destroy/#{object[:id]}")
    }
  end
end

def main
  keys = YAML.load_file("config.yml")

  clients = keys[:twitter].map  { |key| Ammit.new(*key.values) }
                          .each { |client| Thread.new { client.wait } }

  Thread.abort_on_exception = true
  sleep
end

main if __FILE__ == $0
