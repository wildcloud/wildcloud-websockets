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

require 'digest/sha1'
require 'thread'

require 'wildcloud/websockets/java'
require 'wildcloud/websockets/server'

require 'json'
require 'hot_bunnies'
require 'httparty'
require 'sinatra/base'

module Wildcloud
  module Websockets

    class Service

      include SessionCallback

      attr_reader :socket_id, :session_id

      def initialize(engine, socket_id)
        @engine = engine
        @socket_id = socket_id
      end

      def onOpen(session)
        @session = session
      end

      def onClose
        @engine.remove_session(self)
      end

      def onMessage(message)
        @engine.handle_message(self, message)
      end

      def publish(message)
        @session.send(message)
      end

      def onError(error)
        error.print_stack_trace
      end

    end

    class Pusher

      include HTTParty

      def self.queue
        @queue ||= Queue.new
      end

      def initialize(engine)
        @engine = engine
        @thread = Thread.new do
          loop do
            begin
              handler(Pusher.queue.pop)
            rescue Exception => e
              puts e
            end
          end
        end
      end

      def handler(message)
        message = JSON.parse(message)
        self.class.post(message['callback'], :body => JSON.dump({ 'message' => message['message'], 'socket_id' => message['socket_id'] }))
      end

    end

    class Api < Sinatra::Base

      get '/' do
        'Api'
      end

      post '/acceptor' do
        data = JSON.parse(request.body.read)
        HTTParty.post("http://localhost:4567/publish/#{data['socket_id']}", :body => data['message'])
      end

      post '/publish/:socket_id' do
        settings.engine.publish("Echo: #{request.body.read}", params[:socket_id])
        'ok'
      end

      post '/authorize/:application_id/:client_id' do
        data = JSON.parse(request.body.read)
        settings.engine.authorize(params[:application_id], params[:client_id], data[:callback])
      end

    end

    class Engine

      import SessionCallbackFactory

      def initialize
        @router = ServiceRouter.new
        @server = Server.new(@router, '0.0.0.0', 8081)
        @pusher = Pusher.new(self)
        @sockets = {}
        @applications = {}

        authorize('demo', 'demo', 'http://localhost:4567/acceptor')
        register_socket('1e16f7bc75de48ae2a156466a3d0521f525a3187')
      end

      def start
        @server.start
        Api.set(:engine, self)
        Thread.new do
          Api.run!
        end
      end

      def authorize(application_id, client_id, callback)
        socket_id = Digest::SHA1.hexdigest("#{application_id}:#{client_id}")
        @applications[socket_id] = { :application_id => application_id, :client_id => client_id, :callback => callback }
      end

      def publish(message, socket_id)
        @sockets[socket_id].each { |session| session.publish(message) }
      end

      def handle_message(session, message)
        Pusher.queue << JSON.dump({ 'callback' => @applications[session.socket_id][:callback], 'socket_id' => session.socket_id, 'message' => message })
      end

      def register_socket(socket_id)
        service = Service.new(self, socket_id)
        @router.register_service("/#{socket_id}", service, true, 128 * 1024)
        ( @sockets[socket_id] ||= [] ) << service
      end

      def remove_session(session)
        if @sockets.key?(session.socket_id)
          @sockets[session.socket_id].delete(session)
        end
      end

    end
  end
end