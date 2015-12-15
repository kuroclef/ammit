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

require "./ammit"

def test_twitterClient
  keys = YAML.load_file("config.yml")

  clients = keys[:twitter].map  { |key| TwitterClient.new(*key.values) }
                          .each { |client| p client.get("statuses/user_timeline", count: 200) }
end

def test_ammit
  keys = YAML.load_file("config.yml")

  clients = keys[:twitter].map  { |key| Ammit.new(*key.values) }
                          .each { |client| p client.delete_tweets }
end

def test
  test_twitterClient
  test_ammit
end

test if __FILE__ == $0
