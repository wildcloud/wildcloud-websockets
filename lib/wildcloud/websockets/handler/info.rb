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
    module Handler
      class Info < BaseHandler

        def handle_info(socket_id)
          case @request.get_method
            when HttpMethod::OPTIONS
              response_status_no_content
              @response.set_header('Access-Control-Allow-Headers', 'Allow')
              @response.set_header('Access-Control-Allow-Methods', 'OPTIONS, GET')
              @response.set_header('Access-Control-Max-Age', '10000001')
              @response.set_header('Allow', 'OPTIONS,GET')
              response_cache
            when HttpMethod::GET
              websockets = 'true'
              websockets = false if socket_id == 'disabled_websocket_echo' # TODO: remove?
              entropy = Time.now.to_i + rand(1000)
              info = "{\"websocket\":#{websockets},\"origins\":[\"*:*\"],\"cookie_needed\":true,\"entropy\":#{entropy}}"
              @response.remove_header('Set-Cookie')
              response_set_content(info, true)
              response_no_cache
          end
          response_send_header(true)
        end

      end
    end
  end
end