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

require 'wildcloud/websockets/engine'

require 'wildcloud/websockets/websockets/handlers/authorize'
require 'wildcloud/websockets/websockets/handlers/eventsource'
require 'wildcloud/websockets/websockets/handlers/htmlfile'
require 'wildcloud/websockets/websockets/handlers/iframe'
require 'wildcloud/websockets/websockets/handlers/index'
require 'wildcloud/websockets/websockets/handlers/info'
require 'wildcloud/websockets/websockets/handlers/publish'
require 'wildcloud/websockets/websockets/handlers/websockets'
require 'wildcloud/websockets/websockets/handlers/xhr_polling'
require 'wildcloud/websockets/websockets/handlers/xhr_send'
require 'wildcloud/websockets/websockets/handlers/xhr_streaming'

module Wildcloud
  module Websockets
    module Websockets

      class Handler < SimpleChannelUpstreamHandler

        include Wildcloud::Websockets::Websockets::Handlers::Authorize
        include Wildcloud::Websockets::Websockets::Handlers::Eventsource
        include Wildcloud::Websockets::Websockets::Handlers::Htmlfile
        include Wildcloud::Websockets::Websockets::Handlers::Iframe
        include Wildcloud::Websockets::Websockets::Handlers::Index
        include Wildcloud::Websockets::Websockets::Handlers::Info
        include Wildcloud::Websockets::Websockets::Handlers::Publish
        include Wildcloud::Websockets::Websockets::Handlers::Websockets
        include Wildcloud::Websockets::Websockets::Handlers::XhrPolling
        include Wildcloud::Websockets::Websockets::Handlers::XhrSend
        include Wildcloud::Websockets::Websockets::Handlers::XhrStreaming

        # Netty related methods

        def messageReceived(context, event)
          request = event.message
          @channel = context.channel
          # Websockets frames are handled differently
          return handle_websockets_frame(request) if request.kind_of?(WebSocketFrame)
          # Process HTTP request
          @request = request
          @response_content_length = 0
          @response = DefaultHttpResponse.new(HttpVersion::HTTP_1_1, HttpResponseStatus::OK)
          @response.set_header('Access-Control-Allow-Credentials', 'true')
          @response.set_header('Access-Control-Allow-Origin', 'http://localhost')
          @response.set_header('Connection', 'keep-alive')
          @response.set_header('Content-Type', 'application/json; charset=UTF-8')
          cookie = request_header('Cookie')
          cookie ||= 'JSESSIONID=dummy'
          @response.set_header('Set-Cookie', "#{cookie};path=/")
          puts '----------'
          puts @request
          puts '----------'
          case
            when match = /^\/([^\/]+)\/([^\/\.]+)\/([^\/\.]+)\/websocket$/.match(request.uri)
              handle_websockets(match[1], match[2], match[3])
            when match = /^\/authorize\/([^\/]+)\/([^\/]+)$/.match(request.uri)
              handle_authorize(match[1], match[2])
            when match = /^\/publish\/([^\/]+)$/.match(request.uri)
              handle_publish(match[1])
            when match = /^\/([^\/]+)\/info$/.match(request.uri)
              handle_info(match[1])
            when match = /^\/([^\/]+)\/iframe(-[a-zA-Z0-9\.\-]*)?\.html(\?t=(.*))?$/.match(request.uri)
              handle_iframe(match[1])
            when match = /^\/([^\/]+)\/([^\/\.]+)\/([^\/\.]+)\/htmlfile\?c=(.*)$/.match(request.uri)
              handle_htmlfile(match[1], match[2], match[3], match[4])
            when match = /^\/([^\/]+)\/([^\/\.]+)\/([^\/\.]+)\/eventsource$/.match(request.uri)
              handle_eventsource(match[1], match[2], match[3])
            when match = /^\/([^\/]+)\/([^\/\.]+)\/([^\/\.]+)\/xhr_streaming$/.match(request.uri)
              handle_xhr_streaming(match[1], match[2], match[3])
            when match = /^\/([^\/]+)\/([^\/\.]+)\/([^\/\.]+)\/xhr$/.match(request.uri)
              handle_xhr_polling(match[1], match[2], match[3])
            when match = /^\/([^\/]+)\/([^\/\.]+)\/([^\/\.]+)\/xhr_send$/.match(request.uri)
              handle_xhr_send(match[1], match[2], match[3])
            when match = /^\/([^\/]+)(\/)?$/.match(request.uri)
              handle_index
            else
              @channel.write(DefaultHttpResponse.new(HttpVersion::HTTP_1_1, HttpResponseStatus::NOT_FOUND)).addListener(ChannelFutureListener.CLOSE)
          end
        end

        def channelClosed(context, event)
          on_closed_connection(@socket_id, @session_id, self)
        end

        # Callbacks for this implementation

        def on_new_connection(socket_id, session_id, handler)
          puts "New connection #{socket_id}"
          Engine.instance.add_socket(socket_id, session_id, handler)
        end

        def on_message(socket_id, message)
          puts "New message #{message} on socket #{socket_id}"
          Engine.instance.on_message(socket_id, message)
        end

        def on_closed_connection(socket_id, session_id, handler)
          puts "Closed connection #{socket_id}"
          Engine.instance.remove_socket(socket_id, session_id, handler)
        end

        # HTTP request helpers

        def request_body
          @request.content.to_string(Charset.for_name('UTF-8'))
        end

        def request_header(name)
          @request.get_header(name)
        end

        # HTTP response helpers

        def response_status_no_content
          @response.status = HttpResponseStatus::NO_CONTENT
        end

        def response_status_not_found
          @response.status = HttpResponseStatus::NOT_FOUND
        end

        def response_status_not_modified
          @response.status = HttpResponseStatus::NOT_MODIFIED
        end

        def response_status_bad_request
          @response.status = HttpResponseStatus::BAD_REQUEST
        end

        def response_status_method_not_allowed
          @response.status = HttpResponseStatus::METHOD_NOT_ALLOWED
        end

        def response_status_interval_server_error
          @response.status = HttpResponseStatus::INTERNAL_SERVER_ERROR
        end

        def response_no_cache
          @response.set_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        end

        def response_cache
          @response.set_header('Access-Control-Max-Age', '10000001')
          @response.set_header('Cache-Control', 'public, max-age=31536000, must-revalidate')
          @@etag ||= Time.now.to_i.to_s
          @response.set_header('etag', @@etag) # ToDo: etags
          @response.set_header('Expires', Time.now.to_s) # ToDo : in future
        end

        def response_send_header(close = false)
          puts '----------'
          puts @response
          puts '----------'
          future = @channel.write(@response)
          future.addListener(ChannelFutureListener.CLOSE) if close
          future.addListener(ChannelFutureListener.CLOSE) if !close && @response_content_length >= 4096
        end

        def response_set_content(data, length = false)
          @response.set_content(ChannelBuffers.wrapped_buffer(data.to_java_bytes))
          HttpHeaders.set_content_length(@response, data.size) if length
          @response_content_length += data.size
        end

        def response_send_content(data, close = false)
          puts "<< #{data.inspect}"
          future = @channel.write(ChannelBuffers.wrapped_buffer(data.to_java_bytes))
          future.addListener(ChannelFutureListener.CLOSE) if close
          @response_content_length += data.size
          future.addListener(ChannelFutureListener.CLOSE) if !close && @response_content_length >= 4096
        end

        # Utilities

        def encode_message(message)
          message = [message.to_s] unless message.kind_of?(Array)
          "a#{MultiJson.encode(message)}\n"
        end

        def call(message)
          puts "Publishing #{message} for #{@request.uri}" unless @type == :websockets
          case @type
            when :websockets
              data = encode_message(message)
              @response_content_length += data.size
              @channel.write(TextWebSocketFrame.new(data))
            when :xhr_streaming
              data = encode_message(message)
              @response_content_length += data.size
              @channel.write(ChannelBuffers.wrapped_buffer(data.to_java_bytes))
            when :eventsource
              data = "data: #{encode_message(message)}\r\n\r\n"
              @response_content_length += data.size
              @channel.write(ChannelBuffers.wrapped_buffer(data.to_java_bytes))
            when :htmlfile
              data ="<script>\np('#{encode_message(message).chop}');\n</script>\r\n"
              @response_content_length += data.size
              @channel.write(ChannelBuffers.wrapped_buffer(data.to_java_bytes))
            when :xhr_polling
              data = encode_message(message)
              @response_content_length += data.size
              @channel.write(ChannelBuffers.wrapped_buffer(data.to_java_bytes)).addListener(ChannelFutureListener.CLOSE)
          end
          puts @response_content_length.inspect
          future.addListener(ChannelFutureListener.CLOSE) if @response_content_length >= 4096
        end

        def close(reason, code = 3000)
          case @type
            when :websockets
              message = "c[#{code},\"#{reason}\"]"
              @channel.write(TextWebSocketFrame.new(message)).addListener(ChannelFutureListener.CLOSE)
            else
              message = "c[#{code},\"#{reason}\"]\n"
              @channel.write(ChannelBuffers.wrapped_buffer(message.to_java_bytes)).addListener(ChannelFutureListener.CLOSE)
          end
        end

      end

    end
  end
end