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
        module Htmlfile

          HTMLFILE_HTML = <<HTML
<!doctype html>
<html><head>
<meta http-equiv="X-UA-Compatible" content="IE=edge" />
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head><body><h2>Don't panic!</h2>
<script>
    document.domain = document.domain;
    var c = parent.%s;
    c.start();
    function p(d) {c.message(d);};
    window.onload = function() {c.stop();};
</script>
<script>
p("o");
</script>
HTML

          def handle_htmlfile(socket_id, server_id, session_id, callback)
            response_set_content(HTMLFILE_HTML % callback)
            @response.set_header('Content-Type', 'text/html; charset=UTF-8')
            response_send_header

            @type = :htmlfile
            @socket_id = socket_id
            @session_id = session_id
            on_new_connection(@socket_id, session_id, self)
          end

        end
      end
    end
  end
end