class QrCodesController < ApplicationController
  layout false

  def index
    if Whatsapp::Client.already_active_session?
      @message = "Whatsapp já está conectado"
    else
      Whatsapp::Client.create_session unless Whatsapp::Client.waiting_for_qr_code_scan?
      sleep 5
      if Whatsapp::Client.waiting_for_qr_code_scan?
        @qr_code_image = Whatsapp::Client.base64_qr_code_image
      end
    end
  end
end
