require "http/web_socket"
require "json"
require "random/secure"
require "../../session/manager"
require "../../agent/loop"
require "../handlers/logs_handler"

module Crybot
  module Web
    class ChatSocket
      property socket_id : String

      def initialize(@agent : Agent::Loop, @sessions : Session::Manager)
        @socket_id = ""
        @session_id = ""
      end

      def on_open(socket) : Nil
        # Generate unique socket ID and session ID
        @socket_id = generate_session_key
        @session_id = "web_#{Random::Secure.hex(16)}"

        # Store session_id on the socket for later use
        socket.__session_id = @session_id

        # TODO: Fix logging
        # Crybot::Web::Handlers::LogsHandler.log("INFO", "Web client connected (session: #{@session_id})")

        # Send welcome message
        socket.send({
          type:       "connected",
          session_id: @session_id,
          socket_id:  @socket_id,
        }.to_json)
      end

      def on_message(socket, message : String) : Nil
        data = JSON.parse(message)

        case data["type"]?.try(&.as_s)
        when "message"
          handle_chat_message(socket, data)
        when "history_request"
          session_id = data["session_id"]?.try(&.as_s) || @session_id
          send_history(socket, session_id)
        when "session_switch"
          switch_session(socket, data)
        else
          socket.send({
            type:    "error",
            message: "Unknown message type",
          }.to_json)
        end
      rescue e : JSON::ParseException
        socket.send({
          type:    "error",
          message: "Invalid JSON",
        }.to_json)
      rescue e : Exception
        socket.send({
          type:    "error",
          message: e.message,
        }.to_json)
      end

      def on_close(socket) : Nil
        # Clean up if needed
      end

      private def generate_session_key : String
        "sock_#{Random::Secure.hex(8)}"
      end

      private def handle_chat_message(socket, data : JSON::Any) : Nil
        session_id = data["session_id"]?.try(&.as_s) || @session_id
        content = data["content"]?.try(&.as_s) || ""

        if content.empty?
          socket.send({
            type:    "error",
            message: "Message content is empty",
          }.to_json)
          return
        end

        # Send acknowledgment that message is being processed
        socket.send({
          type:   "status",
          status: "processing",
        }.to_json)

        # Process with agent (this blocks until complete)
        response = @agent.process(session_id, content)

        # Send response
        socket.send({
          type:       "response",
          session_id: session_id,
          content:    response,
          timestamp:  Time.local.to_s("%Y-%m-%dT%H:%M:%S%:z"),
        }.to_json)
      end

      private def send_history(socket, session_id : String) : Nil
        messages = @sessions.get_or_create(session_id)

        socket.send({
          type:       "history",
          session_id: session_id,
          messages:   messages.map do |msg|
            {
              role:    msg.role,
              content: msg.content,
            }
          end,
        }.to_json)
      end

      private def switch_session(socket, data : JSON::Any) : Nil
        new_session_id = data["session_id"]?.try(&.as_s)

        if new_session_id.nil? || new_session_id.empty?
          # Create new session
          @session_id = "web_#{Random::Secure.hex(16)}"
        else
          @session_id = new_session_id
        end

        socket.__session_id = @session_id

        socket.send({
          type:       "session_switched",
          session_id: @session_id,
        }.to_json)
      end
    end
  end
end

# Extend HTTP::WebSocket to store custom data
module HTTP
  class WebSocket
    property __session_id : String = ""
  end
end
