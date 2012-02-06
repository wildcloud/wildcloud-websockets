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
      class Iframe < BaseHandler

        IFRAME_HTML = <<HTML
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <script>
    document.domain = document.domain;
    _sockjs_onload = function(){SockJS.bootstrap_iframe();};
  </script>
  <script src="http://cdn.sockjs.org/sockjs-0.2.min.js"></script>
</head>
<body>
  <h2>Don't panic!</h2>
  <p>This is a SockJS hidden iframe. It's used for cross domain magic.</p>
</body>
</html>
HTML

        def handle_iframe(socket_id)
          if request_header('If-None-Match')
            response_status_not_modified
            response_cache
            @response.remove_header('Content-Type')
          else
            @response.set_header('Content-Type', 'text/html; charset=UTF-8')
            @response.remove_header('Set-Cookie')
            response_cache
            response_set_content(IFRAME_HTML, true)
          end
          response_send_header(true)
        end

      end
    end
  end
end