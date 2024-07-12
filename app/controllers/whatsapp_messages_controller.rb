class WhatsappMessagesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    unless remote_ip_allowed_to_request?
      head :forbidden

      return
    end

    send_whatsapp_message

    block_remote_ip
    Rails.cache.delete([ request.remote_ip, :termination_values ])
    head :ok
  end

  private

  def send_whatsapp_message
    return unless Whatsapp::Client.already_active_session?
    return unless valid_phone_number?

    Whatsapp::Client.send_message(
      phone_number: normalized_phone_number,
      message: whastapp_message
    )
  end

  def remote_ip_allowed_to_request?
    Rails.cache.read(request.remote_ip).blank?
  end

  def block_remote_ip
    Rails.cache.write(request.remote_ip, true, expires_in: 2.minutes)
  end

  def normalized_phone_number
    normalized_phone_number = params[:phone_number].gsub(/[\s\-()]/, "")

    if normalized_phone_number.size == 11 && normalized_phone_number[2] == "9"
      normalized_phone_number.slice!(2)
    end

    normalized_phone_number
  end

  def valid_phone_number?
    normalized_phone_number.length >= 10
  end

  def termination_values
    @termination_values ||= Rails.cache.read([ request.remote_ip, :termination_values ])
  end

  def recision_value
    total_value = 0

    termination_values.each do |key, value|
      if key == :fgts
        total_value += value[:total_value]
      else
        total_value += value
      end
    end

    total_value
  end

  def whastapp_message
    <<~MSG
      Olá Sr(a) #{params[:name]}, recebemos sua solicitação para o envio do calculo dos seus direitos trabalhista, a baixo segue uma previsão baseado nos dados preenchidos em nosso formulário. Caso necessite de mais orientações, sinta-se à vontade para falar com a gente através deste WhatsApp. Você receberá informações e orientações gratuitas.

      *Calculo trabalhista:*

      *Dados para o Cálculo*
      Data de Admissão: #{params[:admission_date]}#{' '}
      Data de Demissão: #{params[:demission_date]}#{' '}
      Ultimo Salário: #{params[:salary]}
      Motivo da Rescisão: #{params[:demission_type]}

      ----------------------

      *Descrição das verbas*
      Saldo Salário: #{ format_brl(termination_values[:salary_balance]) }
      13º Salário: #{ format_brl(termination_values[:thirteenth_salary]) }
      Férias: #{ format_brl(termination_values[:vacation_value]) }
      Estimativa do FGTS: #{ format_brl(termination_values[:fgts][:partial_value]) }
      Multa 40% sobre FGTS: #{ format_brl(termination_values[:fgts][:mulct_value]) }
      Aviso prévio: #{ format_brl(termination_values[:notice]) }

      ----------------------

      *Estimativa Total Líquido: #{ format_brl(recision_value) }*
    MSG
  end

  def format_brl(value)
    ActiveSupport::NumberHelper.number_to_currency(value, unit: "R$", separator: ",", delimiter: ".")
  end
end
