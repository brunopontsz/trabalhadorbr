module Termination
  class Calculator
    # calculo de aviso prévio
    def notice(admission_date:, demission_date:, salary:, benefited_company: false)
      admission_date = parse_date(admission_date)
      demission_date = parse_date(demission_date)
      final_value = 0
      salary = salary.to_i

      return final_value unless admission_date && demission_date

      notice_days = count_notice_days(admission_date, demission_date)
      final_value = (salary / 30.0) * notice_days

      final_value = final_value * -1 if benefited_company

      final_value.floor(2)
    rescue => e
      0
    end

    # calculo de decimo terceiro
    def thirteenth_salary(demission_date:, salary:)
      demission_date = parse_date(demission_date)
      worked_months = count_worked_months(start_date: demission_date.beginning_of_year.to_s, end_date: demission_date.to_s)
      final_value = 0
      salary = salary.to_i

      final_value = worked_months * (salary / 12.0)

      final_value.floor(2)

    rescue => e
      0
    end

    # calculo de saldo salário, ou seja, o salário proporcional aos dias trabalhados do mês da demissão
    def salary_balance(salary:, demission_date:)
      demission_date = parse_date(demission_date)
      final_value = 0
      salary = salary.to_i

      final_value = (salary / demission_date.end_of_month.day.to_f) * demission_date.day.to_i

      final_value.floor(2)
    rescue => e
      0
    end

    def fgts(salary:, admission_date:, demission_date:, fired:, thirteenth_salary_fgts_value: 0)
      admission_date = parse_date(admission_date)
      demission_date = parse_date(demission_date)
      salary = salary.to_i

      worked_months = count_worked_months(start_date: admission_date.to_s, end_date: demission_date.to_s)
      mulct_value = 0
      total_value = 0
      partial_value = worked_months * (salary * 0.08)

      if fired
        partial_value = (partial_value + thirteenth_salary_fgts_value)
        mulct_value   =  partial_value * 0.4

        total_value = partial_value + mulct_value
      else
        total_value = (partial_value + thirteenth_salary_fgts_value)
      end

      {
        partial_value: partial_value,
        mulct_value: mulct_value,
        total_value: total_value
      }
    rescue => e
      0
    end

    def vacation(salary:, admission_date:, demission_date:, expired_vacation:, termination_for_cause:)
      admission_date = parse_date(admission_date)
      demission_date = parse_date(demission_date)
      worked_months = count_worked_months(start_date: admission_date.to_s, end_date: demission_date.to_s)
      salary = salary.to_i
      monthly_fraction = salary / 12
      final_value  = 0


      if termination_for_cause
        if worked_months >= 24 && expired_vacation
          constitutional_third = (salary * 2) / 3

          final_value = (salary * 2) + constitutional_third
        end
      else

        proportional_vacation = (worked_months % 12) * monthly_fraction
        proportional_vacation_third = proportional_vacation / 3

        final_value = proportional_vacation + proportional_vacation_third

        if worked_months >= 24 && expired_vacation
          constitutional_third = salary / 3

          final_value += (salary + constitutional_third) * 2
        end
      end

      final_value.floor(2)
    rescue => e
      0
    end

    private

    def count_worked_months(start_date:, end_date:)
      start_date = parse_date(start_date)
      end_date = parse_date(end_date)
      worked_months = 0
      worked_days = 0

      # caso a pessoa seja contratada no mesmo mes que fora demitida
      if start_date.month == end_date.month && start_date.year == end_date.year
        worked_days = (end_date.day - start_date.day).to_i + 1
        worked_months += 1 if worked_days >= 15
      else
        current_date = start_date

        while current_date < end_date
          last_day_of_month = current_date.end_of_month
          worked_days =
            if last_day_of_month < end_date
              (last_day_of_month - current_date).to_i + 1
            else
              (end_date - current_date).to_i + 1
            end

          worked_months += 1 if worked_days >= 15

          current_date = current_date.next_month.beginning_of_month
        end
      end

      worked_months.to_i
    rescue => e
      0
    end

    def parse_date(date_string)
      Date.parse(date_string)
    rescue Date::Error
      date_parts = date_string.split("/")
      day, month, year = date_parts.map(&:to_i)
      last_month_day = Date.civil(year, month, -1).day
      day = [ day, last_month_day ].min
      Date.new(year, month, day)
    end

    def count_notice_days(admission_date, demission_date)
      worked_years = demission_date.year - admission_date.year
      notice_days = 30

      if worked_years <= 1
        notice_days = 30
      elsif worked_years > 1 && worked_years <= 20
        notice_days += (worked_years * 3)
      elsif worked_years > 20
        notice_days = 90
      end

      notice_days.to_i
    end
  end
end
