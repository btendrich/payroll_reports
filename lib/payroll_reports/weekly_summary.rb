module PayrollReports

  class WeeklySummary < PayrollReports::ReportTemplate

    def initialize(payroll_id:)
      @payroll = DB[:payrolls].where(:id => payroll_id).first
    
    
      if @payroll
        @week_ending = @payroll[:week_ending].strftime('%Y-%m-%d')
        @name = @payroll[:name]
        super()
      else
        raise InvalidPayrollID.new("Unknown payroll ID #{payroll_id}")
      end
      
    end
    
    def title
      'Alice Tully Hall'
    end
    
    def heading
      'Payroll Summary'
    end
    
    def headers
      {'Week Ending' => @week_ending, 'Name' => @name}
    end
    
    def qr_code
      Date.parse(@week_ending).strftime('SM%Y%m%d')
    end
    
    def content
      employee_ids = DB[:hours_detail].distinct(:employee_id,:employee_classification,:last_name,:first_name).where(:payroll_id => @payroll[:id]).order_by(:employee_classification,:last_name,:first_name)
      
      employee_ids.each do |id|
        employee = DB[:employees].where(:id => id[:employee_id]).first

        move_down 5
        stroke_color '999999'
        stroke_horizontal_rule
        stroke_color '000000'
        move_down 3

        float do
          text "#{employee[:payroll_file_number]}"
        end
        float do
          indent 50 do
            text "#{employee[:last_name]}, #{employee[:first_name]}"
          end
        end
        indent 300 do
          rates = DB[:hours_detail].distinct(:rate_id,:rate_classification,:rate_name,:rate_short_code).where(:payroll_id => @payroll[:id], :employee_id => employee[:id]).order_by(:rate_classification,:rate_short_code)
          rates.each do |rate|
            quantity = DB[:hours_detail].where(:payroll_id => @payroll[:id], :employee_id => employee[:id], :rate_id => rate[:rate_id]).sum(:quantity)
            text "#{rate[:rate_classification]} - #{rate[:rate_name]}: #{sprintf '%.2f', quantity}"
          end
        end
        
      end
      
      120.times do
        text 'fuck this shit'
      end
    end

  end
  
  class InvalidPayrollID < StandardError; end  

end