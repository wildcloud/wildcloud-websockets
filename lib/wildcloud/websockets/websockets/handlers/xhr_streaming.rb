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

module Wildcloud
  module Websockets
    module Websockets
      module Handlers
        module XhrStreaming

          XHR_STREAMING_HEADER = ('h' * 2048) << "\no\n"

          def handle_xhr_streaming(socket_id, server_id, session_id)
            if @request.get_method == HttpMethod::OPTIONS
              response_cache
              response_status_no_content
              @response.set_header('Access-Control-Allow-Headers', 'Allow')
              @response.set_header('Access-Control-Allow-Methods', 'OPTIONS, POST')
              @response.set_header('Allow', 'OPTIONS,POST')
              response_send_header(true)
              return
            end

            response_no_cache
            response_set_content(XHR_STREAMING_HEADER)
            response_send_header

            @type = :xhr_streaming
            @socket_id = socket_id
            @session_id = session_id
            on_new_connection(@socket_id, session_id, self)
          end

        end
      end
    end
  end
end