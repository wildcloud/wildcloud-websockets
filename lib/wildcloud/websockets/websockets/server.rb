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

require 'wildcloud/websockets/websockets/java'
require 'wildcloud/websockets/websockets/handler'

module Wildcloud
  module Websockets
    module Websockets

      class Server

        def initialize(address = '0.0.0.0', port = 4000)
          @address = address
          @port = port
          @bootstrap = ServerBootstrap.new(NioServerSocketChannelFactory.new(Executors.newCachedThreadPool, Executors.newCachedThreadPool))
          @bootstrap.pipeline_factory = PipelineFactory.new
        end

        def start
          puts "Starting at #{@address} and #{@port}"
          @bootstrap.bind(InetSocketAddress.new(@address, @port))
        end

      end

      class PipelineFactory

        include ChannelPipelineFactory

        def getPipeline
          pipeline = Channels.pipeline
          pipeline.add_last('decoder', HttpRequestDecoder.new)
          pipeline.add_last('aggregator', HttpChunkAggregator.new(65536))
          pipeline.add_last('encoder', HttpResponseEncoder.new)
          pipeline.add_last('handler', Handler.new)
          pipeline
        end

      end

    end
  end
end