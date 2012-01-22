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
        module Eventsource

          def handle_eventsource(socket_id, server_id, session_id)
            @response.set_header('Content-Type', 'text/event-stream; charset=UTF-8')
            response_no_cache
            response_send_header

            response_send_content("\r\n")
            response_send_content("data: o\r\n\r\n")

            @type = :eventsource
            @socket_id = socket_id
            @session_id = session_id
            on_new_connection(@socket_id, session_id, self)
          end

        end
      end
    end
  end
end