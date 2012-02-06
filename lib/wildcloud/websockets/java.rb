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
require File.expand_path('../../../../ext/jackson-core', __FILE__)
require File.expand_path('../../../../ext/jackson-mapper', __FILE__)

module Wildcloud
  module Websockets

    java_import 'java.net.InetSocketAddress'
    java_import 'java.nio.charset.Charset'
    java_import 'java.util.concurrent.Executors'

    java_import 'org.jboss.netty.bootstrap.ServerBootstrap'
    java_import 'org.jboss.netty.buffer.ChannelBuffers'
    java_import 'org.jboss.netty.handler.codec.http.DefaultHttpChunk'
    java_import 'org.jboss.netty.handler.codec.http.DefaultHttpResponse'
    java_import 'org.jboss.netty.handler.codec.http.HttpHeaders'
    java_import 'org.jboss.netty.handler.codec.http.HttpChunkAggregator'
    java_import 'org.jboss.netty.handler.codec.http.HttpMethod'
    java_import 'org.jboss.netty.handler.codec.http.HttpRequest'
    java_import 'org.jboss.netty.handler.codec.http.HttpRequestDecoder'
    java_import 'org.jboss.netty.handler.codec.http.HttpResponseEncoder'
    java_import 'org.jboss.netty.handler.codec.http.HttpResponseStatus'
    java_import 'org.jboss.netty.handler.codec.http.HttpVersion'
    java_import 'org.jboss.netty.handler.codec.http.websocketx.CloseWebSocketFrame'
    java_import 'org.jboss.netty.handler.codec.http.websocketx.PingWebSocketFrame'
    java_import 'org.jboss.netty.handler.codec.http.websocketx.PongWebSocketFrame'
    java_import 'org.jboss.netty.handler.codec.http.websocketx.TextWebSocketFrame'
    java_import 'org.jboss.netty.handler.codec.http.websocketx.WebSocketFrame'
    java_import 'org.jboss.netty.handler.codec.http.websocketx.WebSocketServerHandshakerFactory'
    java_import 'org.jboss.netty.channel.DownstreamMessageEvent'
    java_import 'org.jboss.netty.channel.ChannelDownstreamHandler'
    java_import 'org.jboss.netty.channel.ChannelFutureListener'
    java_import 'org.jboss.netty.channel.ChannelPipeline'
    java_import 'org.jboss.netty.channel.ChannelPipelineFactory'
    java_import 'org.jboss.netty.channel.Channels'
    java_import 'org.jboss.netty.channel.ChannelUpstreamHandler'
    java_import 'org.jboss.netty.channel.SimpleChannelUpstreamHandler'
    java_import 'org.jboss.netty.channel.socket.nio.NioServerSocketChannelFactory'
    java_import 'org.jboss.netty.channel.UpstreamMessageEvent'

  end
end