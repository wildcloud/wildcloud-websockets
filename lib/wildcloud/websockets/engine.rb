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
        @deliveries = {}
        @queue = Queue.new
        @thread = Thread.new do
          loop do
            begin
              url, data = @queue.pop
              url = URI.parse(url)
              http = Net::HTTP.new(url.host, url.port)
              post = Net::HTTP::Post.new(url.path)
              post.body = data
              post['Content-Type'] = 'text/plain'
              response = http.request(post)
            rescue Exception => e
              puts e
            end
          end
        end
        # TODO: remove?
        authorize('echo', '')
        authorize('close', '')
        authorize('disabled_websocket_echo', '')
      end

      def authorize(app_id, user_id)
        socket_id = "#{app_id}#{user_id}"
        @sockets[socket_id] = {:socket_id => socket_id, :app_id => app_id, :user_id => user_id, :sockets => {}, :callback => 'http://localhost:4000/publish/appclient'}
        socket_id
      end

      def validate(socket_id, session_id = nil)
        if session_id
          @sockets.key?(socket_id) && @sockets[socket_id][:sockets].key?(session_id)
        else
          @sockets.key?(socket_id)
        end

      end

      def add_socket(socket_id, session_id, socket)
        return socket.close('Go away!') if socket_id == 'close' # TODO: remove?

        return nil unless @sockets.key?(socket_id)

        return socket.close('Another connection still open', 2010) if @sockets[socket_id][:sockets].key?(session_id)

        @sockets[socket_id][:sockets][session_id] = socket

        #message, @deliveries[socket_id] = @deliveries[socket_id], []
        #publish(socket_id, message)
      end

      def remove_socket(socket_id, session_id, socket)
        return nil unless @sockets.key?(socket_id)
        @sockets[socket_id][:sockets].delete_if { |k,v| v == socket }
      end

      def publish(socket_id, message)
        if @sockets[socket_id] && @sockets[socket_id][:sockets].size > 0
          @sockets[socket_id][:sockets].each { |id, socket| socket.call(message) }
        else
          (@deliveries[socket_id] ||= []) << message
        end
      end

      def on_message(socket_id, message)
        # TODO: remove?
        case socket_id
          when 'echo'
            publish('echo', message)
          when 'disabled_websocket_echo'
            publish('disabled_websocket_echo', message)
          else
            @queue << [@sockets[socket_id][:callback], message]
        end
      end

    end
  end
end