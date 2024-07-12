require "faraday"

module Whatsapp
  class Api
    class << self
      def sessions
        response = http_client.get("sessions")

        response
      end

      def create_session(session_name: "default")
        response = http_client.post("sessions/start") do |req|
          req.body = {
            "name": session_name,
            "config": { "proxy": nil, "debug": false }
          }.to_json
        end

        response
      end

      def qr_code_image_by_session(session_name: "default")
        response =
          http_client.get("#{session_name}/auth/qr?format=image")

        response
      end

      def send_message(session_name: "default", phone_number:, message:)
        response =
          http_client.post("sendText") do |req|
            req.body = {
              "chatId": "55#{phone_number}@c.us",
              "text": message,
              "session": session_name
            }.to_json
          end

        response
      end

      private

      def http_client
        Faraday.new(url: "http://whatsapp-api:3000/api") do |faraday|
          faraday.headers["Accept"] = "image/png, application/json"
          faraday.headers["Content-Type"] = "application/json"
        end
      end
    end
  end
end
