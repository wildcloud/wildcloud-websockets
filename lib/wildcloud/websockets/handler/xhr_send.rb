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

module Wildcloud
  module Websockets
    module Handler

      class XhrSendNoPayloadException < Exception

      end

      class XhrSend < BaseHandler

        def handle_options
          set_strong_cache
          set_status 201
          set_headers 'Access-Control-Allow-Headers' => 'Allow',
                      'Access-Control-Allow-Methods' => 'OPTIONS, POST',
                      'Allow' => 'OPTIONS,POST'
          send_response true
        end

        def handle_post
          #unless Engine.instance.validate(socket_id, session_id) || XhrPolling.xhrs.key?(session_id)
          #  response_status_not_found
          #  response_send_header(true)
          #  return
          #end
          set_no_cache
          set_status 204
          set_headers 'Content-Type' => 'text/plain; charset=UTF-8'

          data = get_content
          raise XhrSendNoPayloadException.new('No payload.') if !data || data == ''

          data = MultiJson.decode(data)
          data.each { |message| on_message(message) }
          send_response(true)
        rescue XhrSendNoPayloadException => e
          set_content("Payload expected.")
          set_status(500)
          send_response(true)
        rescue MultiJson::DecodeError => e
          set_content("Broken JSON encoding.")
          set_status(500)
          send_response(true)
        end

      end

    end
  end
end