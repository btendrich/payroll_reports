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
    
    def footer
      super
      footer_height = 1.in
      repeat :all do
        bounding_box([bounds.left+1.in, bounds.bottom-footer_height], :width => 3.in, :height => bounds.bottom-footer_height) do
          stroke_color '0000ff'
#          text_box "lots of crap...", :at => [bounds.bottom, bounds.left], :width => 3.25.in, :height => 1.in, :valign => :bottom
#          stroke_bounds
        end
      end

    end
    
    def content
      
      table_data = []

      results = DB.fetch( "SELECT employee_id,employee_classification,last_name,first_name,employee_code,rate_short_code,rate_classification,rate_name,SUM(quantity) AS quantity FROM hours_detail WHERE payroll_id = ? GROUP BY employee_classification,last_name,first_name,employee_code,rate_short_code,rate_classification,rate_name,employee_id,rate_id ORDER BY employee_classification,last_name,first_name,rate_short_code,rate_id", @payroll[:id] )

      previous_employee_id = nil

      results.each do |row|
        new_row = []
        
        if previous_employee_id != row[:employee_id]
          table_data << []
          new_row << {:content => "#{row[:employee_code]}", :borders => [:top]}
          new_row << {:content => "#{row[:last_name]}, #{row[:first_name]}", :borders => [:top]}
          new_row << {:content => "#{row[:rate_classification]} - #{row[:rate_name]}", :borders => [:top]}
          new_row << {:content => sprintf('%.2f', row[:quantity]), :borders => [:top]}
        else
          new_row << {:content => "", :colspan => 2, :borders => []}
          new_row << {:content => "#{row[:rate_classification]} - #{row[:rate_name]}", :borders => []}
          new_row << {:content => sprintf('%.2f', row[:quantity]), :borders => []}
        end
        table_data << new_row
        previous_employee_id = row[:employee_id]
      end
      
      table( table_data,
        :width => bounds.width,
        :column_widths => { 0 => 65 },
        :cell_style => {
          :padding => 1,
          :border_colors => '999999'
        },
      )
      
      
      120.times do
        text 'fuck this shit'
      end
    end

  end
  
  class InvalidPayrollID < StandardError; end  

end