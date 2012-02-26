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

require 'java'

require File.expand_path('../../../../ext/netty', __FILE__)
require File.expand_path('../../../../ext/sockjs-netty', __FILE__)
require File.expand_path('../../../../ext/jackson-core', __FILE__)
require File.expand_path('../../../../ext/jackson-mapper', __FILE__)

module Wildcloud
  module Websockets

    java_import 'java.net.InetSocketAddress'
    java_import 'java.util.concurrent.Executors'

    java_import 'org.jboss.netty.bootstrap.ServerBootstrap'
    java_import 'org.jboss.netty.handler.codec.http.DefaultHttpChunk'
    java_import 'org.jboss.netty.handler.codec.http.HttpChunkAggregator'
    java_import 'org.jboss.netty.handler.codec.http.HttpRequestDecoder'
    java_import 'org.jboss.netty.handler.codec.http.HttpResponseEncoder'
    java_import 'org.jboss.netty.channel.ChannelPipeline'
    java_import 'org.jboss.netty.channel.ChannelPipelineFactory'
    java_import 'org.jboss.netty.channel.Channels'
    java_import 'org.jboss.netty.channel.socket.nio.NioServerSocketChannelFactory'

    java_import 'com.cgbystrom.sockjs.ServiceRouter'
    java_import 'com.cgbystrom.sockjs.SessionCallbackFactory'
    java_import 'com.cgbystrom.sockjs.SessionCallback'
    java_import 'com.cgbystrom.sockjs.PreflightHandler'

  end
end