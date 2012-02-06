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
      class Websockets < BaseHandler

        def handle_websockets(socket_id, server_id, session_id)

          unless @request.get_method == HttpMethod::GET
            response_status_method_not_allowed
            @response.remove_header('Content-Type')
            @response.set_header('Allow', 'GET')
            response_send_header(true)
            return
          end

          response_status_no_content
          @response.set_header('Access-Control-Allow-Headers', 'Allow,Content-type')
          @response.set_header('Allow', 'OPTIONS,POST')

          handshaker_factory = WebSocketServerHandshakerFactory.new("ws://localhost:4000/socket/#{socket_id}", nil, false)
          @handshaker = handshaker_factory.new_handshaker(@request)

          return handshaker_factory.sendUnsupportedWebSocketVersionResponse(@channel) unless @handshaker

          @handshaker.handshake(@channel, @request)

          @type = :websockets
          @socket_id = socket_id
          @session_id = session_id

          @channel.write(TextWebSocketFrame.new("o"))

          on_new_connection(@socket_id, session_id, self)
        rescue Exception => e
          puts e.message
          puts e.backtrace
          response_status_bad_request
          response_set_content('Can "Upgrade" only to "WebSocket".', true)
          response_send_header(true)
        end

        def handle_websockets_frame(frame)
          case frame
            when CloseWebSocketFrame
              @handshaker.close(@channel, frame).addListener(ChannelFutureListener.CLOSE)
              on_closed_connection(@socket_id, self)
            when PingWebSocketFrame
              @channel.write(PongWebSocketFrame.new(frame.binary_data))
            when TextWebSocketFrame
              handle_websockets_frame_text(frame)
            else
              raise Exception.new('Bad encoding')
          end
        end

        def handle_websockets_frame_text(frame)
          on_message(@socket_id, frame.text)
        end

        def encode_close(reason, code)
          TextWebSocketFrame.new("c[#{code},\"#{reason}\"]")
        end

        def encode_message(message)
          TextWebSocketFrame.new(message)
        end


      end
    end
  end
end