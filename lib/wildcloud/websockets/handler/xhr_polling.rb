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
      class XhrPolling < BaseHandler

        def self.xhrs
          @xhrs ||= {}
        end

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
          set_headers 'Content-Type' => 'application/javascript; charset=UTF-8'

          if XhrPolling.xhrs.key?(@session_id)
            puts "Reconnect to active session  #{self}"
            send_response
            @close_after_message = true
            on_new_connection
          else
            puts "New session #{self}"
            set_content("o\n", true)
            send_response(true)
            @preserve_connection = true
          end

          XhrPolling.xhrs[@session_id] = self

        end

        def on_closed_connection
          XhrPolling.xhrs.delete(@session_id) unless @preserve_connection
          super
        end

      end

    end
  end
end