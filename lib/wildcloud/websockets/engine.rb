# Copyright 2011 Marek Jelen
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'net/http'
require 'singleton'
require 'thread'
require 'uri'

module Wildcloud
  module Websockets
    class Engine

      include Singleton

      def initialize
        @sockets = {}
        @queue = Queue.new
        @thread = Thread.new do
          loop do
            begin
              url, data = @queue.pop
              puts "#{data} to #{url}"
              url = URI.parse(url)
              http = Net::HTTP.new(url.host, url.port)
              post = Net::HTTP::Post.new(url.path)
              post.body = data
              post['Content-Type'] = 'text/plain'
              response = http.request(post)
              puts "Response #{response.code} (#{response.body})"
            rescue Exception => e
              puts e
            end
          end
        end
      end

      def authorize(app_id, user_id)
        socket_id = "#{app_id}#{user_id}"
        @sockets[socket_id] = {:socket_id => socket_id, :app_id => app_id, :user_id => user_id, :sockets => [], :callback => 'http://localhost:4000/publish/appclient'}
        socket_id
      end

      def validate(socket_id)
        @sockets.key?(socket_id)
      end

      def add_socket(socket_id, socket)
        return nil unless @sockets.key?(socket_id)
        @sockets[socket_id][:sockets] << socket
      end

      def remove_socket(socket_id, socket)
        return nil unless @sockets.key?(socket_id)
        @sockets[socket_id][:sockets].delete(socket)
      end

      def publish(socket_id, message)
        @sockets[socket_id][:sockets].each { |socket| socket.call(message) }
      end

      def on_message(socket_id, message)
        @queue << [@sockets[socket_id][:callback], message]
      end

    end
  end
end