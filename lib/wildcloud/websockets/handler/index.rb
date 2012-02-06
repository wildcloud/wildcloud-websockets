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
      class Index < BaseHandler

        def handle_get
          set_headers 'Content-Type' => 'text/plain; charset=UTF-8'
          remove_header('Set-Cookie')
          set_content("Welcome to SockJS!\n", true)
          send_response(true)
        end

      end
    end
  end
end