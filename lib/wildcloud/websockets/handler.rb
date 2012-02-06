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

require 'multi_json'

require 'wildcloud/websockets/handler/base_handler'
require 'wildcloud/websockets/handler/authorize'
require 'wildcloud/websockets/handler/eventsource'
require 'wildcloud/websockets/handler/htmlfile'
require 'wildcloud/websockets/handler/iframe'
require 'wildcloud/websockets/handler/index'
require 'wildcloud/websockets/handler/info'
require 'wildcloud/websockets/handler/publish'
require 'wildcloud/websockets/handler/websockets'
require 'wildcloud/websockets/handler/xhr_polling'
require 'wildcloud/websockets/handler/xhr_send'
require 'wildcloud/websockets/handler/xhr_streaming'

module Wildcloud
  module Websockets

    class Connection < SimpleChannelUpstreamHandler

      attr_accessor :chunked

      # Netty related methods

      def messageReceived(context, event)
        @written_data ||= 0
        @opened ||= true

        if event.message.kind_of?(Fixnum)
          @written_data += event.message
          if @opened and @written_data > 4096
            puts "Closed based on message size #{@written_data}"
            @opened = false
            @channel.write(ChannelBuffers::EMPTY_BUFFER).addListener(ChannelFutureListener::CLOSE)
          end
          return
        end

        @channel = context.channel
        request = event.message

        # Websockets frames are handled differently
        return handle_websockets_frame(request) if request.kind_of?(WebSocketFrame)

        # Routing
        case
          when match = /^\/([^\/]+)\/([^\/\.]+)\/([^\/\.]+)\/websocket$/.match(request.uri)
            @handler = Handler::Websockets.new
            @handler.socket_id = match[1]
            @handler.session_id = match[3]
          when match = /^\/authorize\/([^\/]+)\/([^\/]+)$/.match(request.uri)
            @handler = Handler::Authorize.new
            @handler.application_id = match[1]
            @handler.client_id = match[2]
          when match = /^\/publish\/([^\/]+)(\/([^\/]+))?$/.match(request.uri)
            @handler = Handler::Publish.new
            @handler.socket_id = match[1]
            @handler.session_id = match[2]
          when match = /^\/([^\/]+)\/info$/.match(request.uri)
            @handler = Handler::Info.new
            @handler.socket_id = match[1]
          when match = /^\/([^\/]+)\/iframe(-[a-zA-Z0-9\.\-]*)?\.html(\?t=(.*))?$/.match(request.uri)
            @handler = Handler::Iframe.new
            @handler.socket_id = match[1]
          when match = /^\/([^\/]+)\/([^\/\.]+)\/([^\/\.]+)\/htmlfile(\?c=(.*))?$/.match(request.uri)
            @handler = Handler::Htmlfile.new
            @handler.socket_id = match[1]
            @handler.session_id = match[3]
            @handler.parameters[:callback] = match[5]
          when match = /^\/([^\/]+)\/([^\/\.]+)\/([^\/\.]+)\/eventsource$/.match(request.uri)
            @handler = Handler::Eventsource.new
            @handler.socket_id = match[1]
            @handler.session_id = match[3]
          when match = /^\/([^\/]+)\/([^\/\.]+)\/([^\/\.]+)\/xhr_streaming$/.match(request.uri)
            @handler = Handler::XhrStreaming.new
            @handler.socket_id = match[1]
            @handler.session_id = match[3]
          when match = /^\/([^\/]+)\/([^\/\.]+)\/([^\/\.]+)\/xhr$/.match(request.uri)
            @handler = Handler::XhrPolling.new
            @handler.socket_id = match[1]
            @handler.session_id = match[3]
          when match = /^\/([^\/]+)\/([^\/\.]+)\/([^\/\.]+)\/xhr_send$/.match(request.uri)
            @handler = Handler::XhrSend.new
            @handler.socket_id = match[1]
            @handler.session_id = match[3]
          when match = /^\/([^\/]+)(\/)?$/.match(request.uri)
            @handler = Handler::Index.new
            @handler.socket_id = match[1]
          else
            return @channel.write(DefaultHttpResponse.new(HttpVersion::HTTP_1_1, HttpResponseStatus::NOT_FOUND)).addListener(ChannelFutureListener.CLOSE)
        end
        @handler.connection = self
        @handler.channel = @channel
        @handler.request = request
        @handler.setup
        @handler.send("handle_#{request.get_method.to_s.downcase}")
      end

      def channelClosed(context, event)
        @handler.on_closed_connection if @handler
      end

      def exceptionCaught(context, event)
        puts event.cause.message
        puts event.cause.backtrace
        #java.lang.System.exit(1)
      end

      def write(data, close = false, options = {})
        if data.kind_of?(String)
          data = ChannelBuffers.wrapped_buffer(data.to_java_bytes)
          data = DefaultHttpChunk.new(data) if @chunked
        end
        if @opened
          @future = @channel.write(data)
          @future.addListener(ChannelFutureListener.CLOSE) if close
        end
      end

    end

  end
end