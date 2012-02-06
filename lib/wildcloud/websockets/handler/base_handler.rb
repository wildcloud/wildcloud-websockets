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

require 'wildcloud/websockets/engine'

module Wildcloud
  module Websockets
    module Handler

      class BaseHandler

        def self.etag
          @etag ||= Time.now.to_i.to_s
        end

        attr_accessor :application_id, :client_id, :socket_id, :session_id
        attr_accessor :request, :channel, :connection, :parameters

        def initialize
          @parameters ||= {}
        end

        # HTTP headers management

        def set_status(code)
          @response.status = HttpResponseStatus.valueOf(code)
        end

        def get_header(name)
          @request.get_header(name)
        end

        def set_headers(headers = {})
          headers.each do |name, value|
            @response.set_header(name, value)
          end
        end

        def remove_header(name)
          @response.remove_header(name)
        end

        def set_no_cache
          set_headers 'Cache-Control' => 'no-store, no-cache, must-revalidate, max-age=0'
        end

        def set_strong_cache
          @response.set_header('Access-Control-Max-Age', '10000001')
          @response.set_header('Cache-Control', 'public, max-age=31536000, must-revalidate')
          @response.set_header('etag', BaseHandler.etag) # ToDo: etags
          @response.set_header('Expires', Time.now.to_s) # ToDo: in future
        end


        # HTTP content management

        def send_response(close = false)
          @connection.write(@response, close)
        end

        def set_content(data, length = false)
          @response.set_content(ChannelBuffers.wrapped_buffer(data.to_java_bytes))
          HttpHeaders.set_content_length(@response, data.size) if length
        end

        def send_content(data, close = false)
          @connection.write(data, close)
        end

        def get_content
          @request.content.to_string(Charset.for_name('UTF-8'))
        end

        def set_chunked
          @connection.chunked = true
          @response.set_chunked(true)
          set_headers 'Transfer-Encoding' => 'chunked'
        end


        # Logic

        def setup
          @close_after_message ||= false
          @response = DefaultHttpResponse.new(HttpVersion::HTTP_1_1, HttpResponseStatus::OK)
          set_headers 'Access-Control-Allow-Credentials' => 'true',
                      'Access-Control-Allow-Origin' => 'http://localhost',
                      'Connection' => 'Keep-Alive',
                      'Content-Type' => 'application/json; charset=UTF-8',
                      'Set-Cookie' => "#{get_header('Cookie') or 'JSESSIONID=dummy'};path=/"
        end

        def call(message)
          message = [message.to_s] unless message.kind_of?(Array)
          message = "a#{MultiJson.encode(message)}"

          puts "Publishing #{message} for #{@request.uri}"

          message = encode_message(message)

          if @close_after_message
            @connection.write(message, true)
          else
            @connection.write(message)
          end

        end

        def close(reason, code = 3000)
          @connection.write(encode_close(reason, code), true)
        end

        def encode_close(reason, code)
          "c[#{code},\"#{reason}\"]\n"
        end

        def encode_message(message)
          message
        end


        # Callbacks

        def on_new_connection
          puts "New connection #{@socket_id} (#{self.class.name})"
          Engine.instance.add_socket(@socket_id, @session_id, self)
        end

        def on_message(message)
          puts "New message #{message.inspect} on socket #{@socket_id} (#{self.class.name})"
          Engine.instance.on_message(@socket_id, message)
        end

        def on_closed_connection
          puts "Closed connection #{@socket_id} (#{self.class.name})"
          Engine.instance.remove_socket(@socket_id, @session_id, self)
        end


      end

    end
  end
end
