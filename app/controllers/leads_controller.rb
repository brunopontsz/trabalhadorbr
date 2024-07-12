class LeadsController < ApplicationController
  layout false
  skip_before_action :verify_authenticity_token

  def create
    render partial: "termination_summary", locals: { termination_values: calculate_termination_values }
  end

  private

  def calculate_termination_values
    fgts = 0
    notice = 0
    salary_balance = 0
    thirteenth_salary = 0
    vacation_value = 0
    expired_vacation = lead_params[:expired_vacation] == "Sim" ? true : false
    termination_for_cause = if lead_params[:demission_type] == "Demitido por justa causa"
      true
    else
      false
    end

    benefited_company =
      if params[:demission_type] == "Pediu demissão" && params[:notice_worked] == "Indenizado"
        true
      else
        false
      end

    fired =
      if lead_params[:demission_type] == "Demitido sem justa causa"
        true
      else
        false
      end

    if !termination_for_cause
      notice =
        calculator.notice(
          admission_date: lead_params[:admission_date],
          demission_date: lead_params[:demission_date],
          salary: lead_params[:salary],
          benefited_company: benefited_company
        )

      thirteenth_salary =
        calculator.thirteenth_salary(
          demission_date: lead_params[:demission_date],
          salary: lead_params[:salary]
        )

      thirteenth_salary_fgts_value = thirteenth_salary * 0.08


      unless params[:demission_type] == "Pediu demissão" && (params[:notice_worked] == "Trabalhado" || params[:notice_worked] == "Indenizado")
        fgts = calculator.fgts(
          salary: lead_params[:salary],
          admission_date: lead_params[:admission_date],
          demission_date: lead_params[:demission_date],
          fired: fired,
          thirteenth_salary_fgts_value: thirteenth_salary_fgts_value
        )
      end
    end

    salary_balance =
      calculator.salary_balance(
        salary: lead_params[:salary],
        demission_date: lead_params[:demission_date]
      )

    vacation_value =
      calculator.vacation(
        salary: lead_params[:salary],
        admission_date: lead_params[:admission_date],
        demission_date: lead_params[:demission_date],
        expired_vacation: expired_vacation,
        termination_for_cause: termination_for_cause
      )

    Rails.cache.fetch([ request.remote_ip, :termination_values ], expires_in: 30.seconds) do
      {
        fgts: fgts,
        notice: notice,
        salary_balance: salary_balance,
        thirteenth_salary: thirteenth_salary,
        vacation_value: vacation_value
      }
    end
  end

  def lead_params
    params[:demission_date] = Date.today.strftime("%d/%m/%Y") if params[:demission_date].blank?
    params[:salary] = 1.412 if params[:salary].blank?

    params
  end

  def calculator
    @calculator = Termination::Calculator.new
  end
end
