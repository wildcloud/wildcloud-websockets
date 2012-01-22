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
    module Websockets
      module Handlers
        class XhrSendNoPayloadException < Exception

        end
        module XhrSend

          def handle_xhr_send(socket_id, server_id, session_id)
            case @request.get_method
              when HttpMethod::OPTIONS
                response_cache
                response_status_no_content
                @response.set_header('Access-Control-Allow-Headers', 'Allow')
                @response.set_header('Access-Control-Allow-Methods', 'OPTIONS, POST')
                @response.set_header('Allow', 'OPTIONS,POST')
              when HttpMethod::POST
                unless Engine.instance.validate(socket_id, session_id) || XhrPolling.xhrs.key?(session_id)
                  response_status_not_found
                  response_send_header(true)
                  return
                end
                response_status_no_content
                response_no_cache
                @response.set_header('Content-Type', 'text/plain; charset=UTF-8')

                data = request_body
                raise XhrSendNoPayloadException.new('No payload.') if !data || data == ''

                data = MultiJson.decode(data)
                data.each { |message| on_message(socket_id, message) }
            end
            response_send_header(true)
          rescue XhrSendNoPayloadException => e
            response_set_content("Payload expected.")
            response_status_interval_server_error
            response_send_header(true)
          rescue MultiJson::DecodeError => e
            response_set_content("Broken JSON encoding.")
            response_status_interval_server_error
            response_send_header(true)
          end

        end
      end
    end
  end
end