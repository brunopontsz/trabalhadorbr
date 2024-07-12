require "faraday"

module Rdstation
  class Api
    class << self
      def send_conversion(params)
        return if params[:email].blank? && params[:name].blank?

        payload = build_conversion_payload(params)
        response =
          http_client.post do |req|
            req.body = {
              "event_type": "CONVERSION",
              "event_family": "CDP",
              "payload": payload
            }.to_json
          end

        response.body
      end

      private

      def build_conversion_payload(params)
        {}.tap do |payload|
          payload["conversion_identifier"] = "Ruby Integration"
          payload["email"] = params[:email]
          payload["name"] = params[:name]
          payload["cf_rescisao_atraso"] = [ params[:expired_rescission] ] if params[:expired_rescission].present?
          payload["cf_fgts"] = params[:fgts_deposited_correctly] if params[:fgts_deposited_correctly].present?
          payload["cf_aviso_previo"] = params[:notice_worked] if params[:notice_worked].present?
          payload["cf_pendencia_decimo_terceiro"] = [ params[:thirteenth_pending] ] if params[:thirteenth_pending].present?
          payload["cf_ferias_vencidas"] = [ params[:expired_vacation] ] if params[:expired_vacation].present?
          payload["job_title"] = params[:role] if params[:role].present?
          payload["company_name"] = params[:company] if params[:company].present?
          payload["cf_data_de_admissao"] = params[:admission_date] if params[:admission_date].present?
          payload["cf_data_de_demissao"] = params[:demission_date] if params[:demission_date].present?
          payload["mobile_phone"] = params[:phone_number] if params[:phone_number].present?
          payload["cf_ctps_assinada"] = [ params[:assigned_ctps] ] if params[:assigned_ctps].present?
          payload["cf_tipo_de_demissao"] = params[:demission_type] if params[:demission_type].present?
          payload["cf_salario"] = params[:salary] if params[:salary].present?
        end
      end

      def http_client
        Faraday.new(url: "https://api.rd.services/platform/conversions?api_key=QbjgeUbpsrCAmiECkDbLeSjcJFnmodcuxSAD") do |faraday|
          faraday.request :json
          faraday.response :json
        end
      end
    end
  end
end
