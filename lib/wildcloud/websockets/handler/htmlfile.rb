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

require 'cgi'

module Wildcloud
  module Websockets
    module Handler
      class Htmlfile < BaseHandler

        HTML = "<!doctype html>
<html><head>
  <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\" />
  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
</head><body><h2>Don't panic!</h2>
  <script>
    document.domain = document.domain;
    var c = parent.%s;
    c.start();
    function p(d) {c.message(d);};
    window.onload = function() {c.stop();};
  </script>"

        def handle_get
          if !@parameters[:callback]
            set_status 500
            set_content('"callback" parameter required')
            send_response(true)
            return
          end

          set_headers 'Content-Type' => 'text/html; charset=UTF-8'
          set_chunked
          set_no_cache
          send_response

          send_content(HTML % CGI.unescape(@parameters[:callback]))
          send_content("<script>\np(\"o\");\n</script>\r\n")

          on_new_connection
        end

        def encode_message(message)
          "<script>\np(\"#{message.gsub('"', '\"')}\");\n</script>\r\n" #ToDo: better escaping
        end

      end
    end
  end
end