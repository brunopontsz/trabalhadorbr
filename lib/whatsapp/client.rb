module Whatsapp
  class Client
    class << self
      def waiting_for_qr_code_scan?(session_name: "default")
        response = Whatsapp::Api.sessions
        return false if response.body == "[]"

        parsed_response = JSON.parse(response.body)&.first
        parsed_response["name"] == session_name &&
          parsed_response["status"] == "SCAN_QR_CODE"
      end

      def base64_qr_code_image(session_name: "default")
        response = Whatsapp::Api.qr_code_image_by_session(session_name: session_name)

        Base64.strict_encode64(response.body)
      end

      def create_session(session_name: "default")
        Whatsapp::Api.create_session(session_name: session_name)
      end

      def send_message(session_name: "default", phone_number:, message:)
        Whatsapp::Api.send_message(
          session_name: session_name,
          phone_number: phone_number,
          message: message
        )
      end

      def already_active_session?(session_name: "default")
        response = Whatsapp::Api.sessions

        parsed_response = JSON.parse(response.body)
        parsed_response.any? do |session|
          session["name"] == session_name &&
            session["status"] == "WORKING"
        end
      end
    end
  end
end
