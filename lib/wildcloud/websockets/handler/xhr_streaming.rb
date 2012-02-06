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
      class XhrStreaming < BaseHandler

        XHR_STREAMING_HEADER = ('h' * 2048) << "\n"

        def handle_options
          set_strong_cache
          set_status 204
          set_headers 'Access-Control-Allow-Headers' => 'Allow',
                      'Access-Control-Allow-Methods' => 'OPTIONS, POST',
                      'Allow' => 'OPTIONS,POST'
          send_response(true)
        end

        def handle_post
          set_no_cache
          set_headers 'Connection' => 'Keep-Alive'
          set_chunked

          send_response
          send_content(XHR_STREAMING_HEADER)
          send_content("o\n")

          on_new_connection
        end

      end
    end
  end
end