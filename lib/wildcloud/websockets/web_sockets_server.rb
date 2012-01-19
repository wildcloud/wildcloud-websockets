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

require 'multi_json'

require 'wildcloud/websockets/engine'

module Wildcloud
  module Websockets

    java_import 'java.net.InetSocketAddress'
    java_import 'java.nio.charset.Charset'
    java_import 'java.util.concurrent.Executors'

    java_import 'org.jboss.netty.bootstrap.ServerBootstrap'
    java_import 'org.jboss.netty.buffer.ChannelBuffers'
    java_import 'org.jboss.netty.handler.codec.http.DefaultHttpResponse'
    java_import 'org.jboss.netty.handler.codec.http.HttpHeaders'
    java_import 'org.jboss.netty.handler.codec.http.HttpChunkAggregator'
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
    java_import 'org.jboss.netty.channel.ChannelFutureListener'
    java_import 'org.jboss.netty.channel.ChannelPipeline'
    java_import 'org.jboss.netty.channel.ChannelPipelineFactory'
    java_import 'org.jboss.netty.channel.Channels'
    java_import 'org.jboss.netty.channel.SimpleChannelUpstreamHandler'
    java_import 'org.jboss.netty.channel.socket.nio.NioServerSocketChannelFactory'

    class WebSocketsServer

      def initialize(address = '0.0.0.0', port = 4000)
        @address = address
        @port = port
        @bootstrap = ServerBootstrap.new(NioServerSocketChannelFactory.new(Executors.newCachedThreadPool, Executors.newCachedThreadPool))
        @bootstrap.pipeline_factory = WebSocketsServerPipelineFactory.new
      end

      def start
        puts "Starting at #{@address} and #{@port}"
        @bootstrap.bind(InetSocketAddress.new(@address, @port))
      end

    end

    class WebSocketsServerHandler < SimpleChannelUpstreamHandler

      def messageReceived(context, event)
        message = event.message
        case message
          when HttpRequest
            handle_http(context, message)
          when WebSocketFrame
            handle_ws(context, message)
        end
      end

      def handle_http(context, request)
        case
          when match = /^\/authorize\/([^\/]+)\/([^\/]+)$/.match(request.uri)
            handle_authorize(context, request, match[1], match[2])
          when match = /^\/publish\/([^\/]+)$/.match(request.uri)
            handle_publish(context, request, match[1])
          when match = /^\/([^\/]+)\/info$/.match(request.uri)
            handle_info(context, request, match[1])
          when match = /^\/([^\/]+)\/([^\/]+)\/([^\/]+)\/websocket$/.match(request.uri)
            handle_ws_handshake(context, request, match[1], match[2], match[3])
          else
            context.channel.write(DefaultHttpResponse.new(HttpVersion::HTTP_1_1, HttpResponseStatus::FORBIDDEN)).addListener(ChannelFutureListener.CLOSE)
        end
      end

      def handle_info(context, request, socket_id)
        info = "{\"websocket\":true,\"origins\":[\"*:*\"],\"cookie_needed\":true,\"entropy\":#{Time.now.to_i}}"
        response = DefaultHttpResponse.new(HttpVersion::HTTP_1_1, HttpResponseStatus::OK)
        HttpHeaders.set_content_length(response, info.size)
        response.set_content(ChannelBuffers.wrapped_buffer(info.to_java_bytes))
        response.set_header('Access-Control-Allow-Credentials', 'true')
        response.set_header('Access-Control-Allow-Origin', 'http://localhost')
        response.set_header('Content-Type', 'application/json; charset=UTF-8')
        response.set_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        context.channel.write(response).addListener(ChannelFutureListener.CLOSE)
      end

      def handle_authorize(context, request, app_id, user_id)
        # localhost:4000/authorize/app/client
        socket_id = Engine.instance.authorize(app_id, user_id)
        response = DefaultHttpResponse.new(HttpVersion::HTTP_1_1, HttpResponseStatus::OK)
        HttpHeaders.set_content_length(response, socket_id.size)
        response.set_content(ChannelBuffers.wrapped_buffer(socket_id.to_java_bytes))
        context.channel.write(response).addListener(ChannelFutureListener.CLOSE)
      end

      def handle_publish(context, request, socket_id)
        response = DefaultHttpResponse.new(HttpVersion::HTTP_1_1, HttpResponseStatus::OK)
        HttpHeaders.set_content_length(response, 2)
        response.set_content(ChannelBuffers.wrapped_buffer('OK'.to_java_bytes))
        context.channel.write(response).addListener(ChannelFutureListener.CLOSE)

        data = request.content.to_string(Charset.for_name('UTF-8'))
        puts data
        Engine.instance.publish(socket_id, data)
      end

      def handle_ws_handshake(context, request, socket_id, server_id, session_id)
        unless Engine.instance.validate(socket_id)
          return context.channel.write(DefaultHttpResponse.new(HttpVersion::HTTP_1_1, HttpResponseStatus::FORBIDDEN)).addListener(ChannelFutureListener.CLOSE)
        end
        @handshaker_factory = WebSocketServerHandshakerFactory.new("ws://localhost:4000/socket/#{socket_id}", nil, false)
        @handshaker = @handshaker_factory.new_handshaker(request)
        return @handshaker_factory.sendUnsupportedWebSocketVersionResponse(context.channel) unless @handshaker
        @handshaker.handshake(context.channel, request)
        @channel = context.channel
        @socket_id = socket_id
        Engine.instance.add_socket(@socket_id, self)
        @channel.write(TextWebSocketFrame.new("o\n"))
      end

      def handle_ws(context, frame)
        case frame
          when CloseWebSocketFrame
            @handshaker.close(context.channel, frame).addListener(ChannelFutureListener.CLOSE)
            Engine.instance.remove_socket(@socket_id, self)
          when PingWebSocketFrame
            context.channel.write(PongWebSocketFrame.new(frame.binary_data))
          when TextWebSocketFrame
            handle_ws_text_frame(context, frame)
          else
            raise Exception.new('Bad encoding')
        end
      end

      def publish(message)
        message = [message.to_s] unless message.kind_of?(Array)
        message = "a#{MultiJson.encode(message)}\n"
        @channel.write(TextWebSocketFrame.new(message))
      end

      def close(reason)
        message = "c[3000,\"#{reason}\"]"
        @channel.write(TextWebSocketFrame.new(message))
      end

      def handle_ws_text_frame(context, frame)
        Engine.instance.on_message(@socket_id, frame.text)
      end

    end

    class WebSocketsServerPipelineFactory

      include ChannelPipelineFactory

      def getPipeline
        pipeline = Channels.pipeline
        pipeline.add_last('decoder', HttpRequestDecoder.new)
        pipeline.add_last('aggregator', HttpChunkAggregator.new(65536))
        pipeline.add_last('encoder', HttpResponseEncoder.new)
        pipeline.add_last('handler', WebSocketsServerHandler.new)
        pipeline
      end

    end

  end
end