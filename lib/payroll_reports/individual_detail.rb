module PayrollReports

  class IndividualDetail < PayrollReports::ReportTemplate

    def initialize(employee_id:, payroll_id: nil)
      @employee = DB[:employees].where(:id => employee_id).first
    
    
      if @employee
        if payroll_id.nil?
          results = DB.fetch("SELECT id FROM payrolls WHERE id IN (SELECT DISTINCT payroll_id FROM hours WHERE employee_id = ?) ORDER BY week_ending DESC LIMIT 1", @employee[:id])
          payroll_id = results.first[:id]
        end
        @payroll = DB[:payrolls].where(:id => payroll_id).first
        if @payroll
          super()
        else
          raise InvalidPayrollID.new("Unknown payroll ID #{payroll_id}")
        end
      else
        raise InvalidEmployeeID.new("Unknown employee ID #{employee_id}")
      end
      
    end
    
    def title
      'Alice Tully Hall'
    end
    
    def heading
      'Individual Payroll Detail'
    end
    
    def headers
      {'Week Ending' => @week_ending, 'Name' => @name}
    end
    
    def qr_code
      check_date = @payroll[:week_ending] + 3
      results = DB.fetch("SELECT sum(total) AS total FROM hours_detail WHERE employee_id = ? AND payroll_id = ?", @employee[:id], @payroll[:id]).first
      gross_pay = 0
      "BEGIN:VEVENT
SUMMARY:Alice Tully Hall Check
DESCRIPTION:Check Gross: #{sprintf('%.2f', results[:total])}
DTSTART:#{(@payroll[:week_ending]-6).strftime '%Y%m%d'}
DTEND:#{(@payroll[:week_ending]+1).strftime '%Y%m%d'}
END:VEVENT"
    end
    
    def footer
      super
      footer_height = 1.in
      repeat :all do
        bounding_box([bounds.left+1.in, bounds.bottom-footer_height], :width => 3.in, :height => bounds.bottom-footer_height) do
          text_box "This is a beta version of this software. This information may not accurately reflect the actual payroll or expected gross pay. Do not rely on this for anything.", :at => [bounds.bottom, bounds.left], :width => 3.25.in, :height => 1.in, :valign => :bottom, :size => 8
        end
      end

    end
    
    def content
      
      float do
        indent 4.25.in do
          table(
          [
            [{:content => "Payroll File:", :size => 10, :align => :right, :background_color => "D0D0D0"},{:content => "#{@employee[:payroll_file_number]}", :size => 10}],
            [{:content => "Card Number:", :size => 10, :align => :right, :background_color => "D0D0D0"},{:content => "#{@employee[:card_number]}", :size => 10}],
          ],
          :cell_style => {
            :padding => 3,
            :border_color => "666666",
          },
          :width => 3.5.in,
          )
        end
      end
      
      indent 0.25.in do
        table(
        [
          [{:content => "Employee Name:", :size => 10, :align => :right, :background_color => "D0D0D0"},{:content => "#{@employee[:last_name]}, #{@employee[:first_name]}", :size => 10}],
          [{:content => "Payroll Week Ending:", :size => 10, :align => :right, :background_color => "D0D0D0"},{:content => "#{@payroll[:week_ending]}", :size => 10}],
          [{:content => "Database Record:", :size => 10, :align => :right, :background_color => "D0D0D0"},{:content => "#{@employee[:id]}", :size => 10}],
        ],
        :cell_style => {
          :padding => 3,
          :border_color => "666666",
        },
        :width => 3.5.in,
        )
      end

      move_down 20
      
      # select * from hours_details where payroll_id = 2479 and employee_id = 3 order by date,rate_short_code;
      results = DB.fetch( "SELECT * FROM hours_details WHERE payroll_id = ? AND employee_id = ? ORDER BY date,rate_short_code", @payroll[:id], @employee[:id])
      
      data = []
      data << [
        {:content => "Date", :size => 12, :align => :center, :background_color => "D0D0D0"},
        {:content => "Rate", :size => 12, :align => :center, :background_color => "D0D0D0"},
        {:content => "Amount", :size => 12, :align => :center, :background_color => "D0D0D0"},
        {:content => "Quantity", :size => 12, :align => :center, :background_color => "D0D0D0"},
        {:content => "Total", :size => 12, :align => :center, :background_color => "D0D0D0"},
        {:content => "Notes", :size => 12, :align => :center, :background_color => "D0D0D0"},
      ]
      
      # individual items
      previous_day = nil
      row_number = 1
      results.each do |row|
        
        bgcolor = ( row_number % 2 == 0 ? 'FFFFFF' : 'E7E7E7')
        bgcolor = "FFFFFF"
        
        if row[:date] != previous_day 
          data << [{:content => "", :colspan => 6, :background_color => "D0D0D0"}] unless previous_day.nil?
        end
        previous_day = row[:date]
        
        data << [
          {:content => "#{row[:date].strftime '%A'}\n#{row[:date].strftime '%b %e, %Y'}", :size => 9, :align => :left, :background_color => bgcolor},
          {:content => "#{row[:rate_short_code]}\n(#{row[:rate_classification]} - #{row[:rate_name]})", :size => 9, :align => :left, :background_color => bgcolor},
          {:content => display_as_currency(row[:rate_amount]), :size => 9, :align => :left, :background_color => bgcolor},
          {:content => sprintf('%.2f', row[:quantity]), :size => 9, :align => :left, :background_color => bgcolor},
          {:content => display_as_currency(row[:total]), :size => 9, :align => :left, :background_color => bgcolor},
          {:content => "#{row[:notes]}", :size => 9, :align => :left, :background_color => bgcolor},
        ]
        row_number = row_number + 1
      end
      
      # totals
      # select sum(total) from hours_details where payroll_id = 2479 and employee_id = 3;
      data << [{:content => "", :colspan => 6, :background_color => "D0D0D0"}] unless previous_day.nil?
      results = DB.fetch( "SELECT SUM(quantity) AS quantity,SUM(total) AS total FROM hours_details WHERE payroll_id = ? AND employee_id = ?", @payroll[:id], @employee[:id] ).first
      total_earnings = results[:total]
      data << [
        {:content => "Total:", :size => 9, :align => :right, :colspan => 3},
        {:content => sprintf('%.2f', results[:quantity]), :size => 9, :align => :left},
        {:content => sprintf('$%.4f', results[:total]), :size => 9, :align => :left},
      ]
      
      table(
      data,
      :width => bounds.width,
      :column_widths => { 0 => 65, 2 => 65, 3 => 65, 4 => 65 },
      :cell_style => {
        :padding => 3,
        :border_color => "666666",
      },
      :header => true
      )
      
      move_down 20
      
      table_data = []
      
      table_data << [
        {:content => "Item", :size => 10, :align => :left, :background_color => "D0D0D0"},
        {:content => "Rate", :size => 10, :align => :left, :background_color => "D0D0D0"},
        {:content => "This Period", :size => 10, :align => :left, :background_color => "D0D0D0"},
      ]
      
      
      indent 0.5.in do
        # annuity contributions
        float do
          indent 3.75.in do
            # if extra employee calculate their vacation information:
            if @employee[:classification] == 'Extra'
        
              results = DB.fetch( "SELECT DISTINCT vacation_rate FROM time_periods WHERE begins <= ? AND ends >= ?", @payroll[:week_ending], @payroll[:week_ending]).first
              current_vacation_rate = results[:vacation_rate]

              ytd_start = nil
              if @payroll[:week_ending] < Date.parse("#{@payroll[:week_ending].strftime('%Y')}-07-01")
                ytd_start = @payroll[:week_ending].prev_year.strftime('%Y-07-01')
              else
                ytd_start = @payroll[:week_ending].strftime('%Y-07-01')
              end

              results = DB.fetch( "select sum(hours.quantity * rates.amount * (time_periods.vacation_rate/100)) as total from hours, rates, time_periods, payrolls where hours.payroll_id = payrolls.id AND hours.rate_id = rates.id AND rates.time_period_id = time_periods.id AND employee_id = ? AND payroll_id IN (SELECT id FROM payrolls WHERE week_ending >= ? AND week_ending <= ?)", @employee[:id], ytd_start, @payroll[:week_ending] ).first
              fiscal_ytd_vacation = results[:total]
              
              table_data = []
              table_data << [{:content => "Vacation", :size => 10, :align => :center, :background_color => "D0D0D0", :colspan => 2}]
              table_data << [{:content => "Current Rate:", :size => 10, :align => :right, :background_color => "D0D0D0"}, {:content => sprintf("%.2f%%", current_vacation_rate), :size => 10, :align => :left}]
              table_data << [{:content => "Contribution This Time Period:", :size => 10, :align => :right, :background_color => "D0D0D0"}, {:content => display_as_currency(total_earnings*(current_vacation_rate/100)), :size => 10, :align => :left}]
              table_data << [{:content => "Contributions Fiscal YTD:", :size => 10, :align => :right, :background_color => "D0D0D0"}, {:content => display_as_currency(fiscal_ytd_vacation), :size => 10, :align => :left}]      
              table( table_data,
                :cell_style => {
                  :padding => 3,
                  :border_color => "666666"
                },
                :width => 3.25.in,
              )
        
            else
              ytd_start = nil
              if @payroll[:week_ending] < Date.parse("#{@payroll[:week_ending].strftime('%Y')}-09-01")
                ytd_start = @payroll[:week_ending].prev_year.strftime('%Y-09-01')
              else
                ytd_start = @payroll[:week_ending].strftime('%Y-09-01')
              end

              results = DB.fetch( "SELECT sum(quantity)/8 AS total FROM hours,rates,payrolls WHERE hours.payroll_id = payrolls.id AND hours.rate_id = rates.id AND rates.short_code = 'Sick' AND employee_id = ? AND hours.date >= ? AND hours.date <= ?", @employee[:id], ytd_start, @payroll[:week_ending] ).first
              sick_days_used = results[:total].to_i

              results = DB.fetch( "SELECT sum(quantity)/8 AS total FROM hours,rates,payrolls WHERE hours.payroll_id = payrolls.id AND hours.rate_id = rates.id AND rates.short_code = 'Vacation' AND employee_id = ? AND hours.date >= ? AND hours.date <= ?", @employee[:id], ytd_start, @payroll[:week_ending] ).first
              vacation_days_used = results[:total].to_i
              
              table_data = []
              table_data << [{:content => "Sick / Vacation Days", :size => 10, :align => :center, :background_color => "D0D0D0", :colspan => 2}]
              table_data << [{:content => "Sick Days Used:\n(contract year-to-date)", :size => 10, :align => :right, :background_color => "D0D0D0"}, {:content => sick_days_used.to_s, :size => 10, :align => :left}]
              table_data << [{:content => "Vacation Days Used:\n(contract year-to-date)", :size => 10, :align => :right, :background_color => "D0D0D0"}, {:content => vacation_days_used.to_s, :size => 10, :align => :left}]

              table( table_data,
                :cell_style => {
                  :padding => 3,
                  :border_color => "666666"
                },
                :width => 3.25.in,
              )

            end
          end
        end

        column_name = ''
        if @employee[:classification] == 'Extra'
          column_name = 'annuity_rate_extra'
        else
          column_name = 'annuity_rate_basic'
        end
  
        results = DB.fetch( "SELECT DISTINCT #{column_name} FROM time_periods WHERE begins <= ? AND ends >= ?", @payroll[:week_ending], @payroll[:week_ending]).first
        current_annuity_rate = results[column_name.to_sym]

        mtd_start = @payroll[:week_ending].strftime('%Y-%m-01')
        results = DB.fetch( "select sum(hours.quantity * rates.amount * (time_periods.#{column_name}/100)) as total from hours, rates, time_periods, payrolls where hours.payroll_id = payrolls.id AND hours.rate_id = rates.id AND rates.time_period_id = time_periods.id AND employee_id = ? AND payroll_id IN (SELECT id FROM payrolls WHERE week_ending >= ? AND week_ending <= ?)", @employee[:id], mtd_start, @payroll[:week_ending] ).first
        mtd_annuity = results[:total]

        ytd_start = @payroll[:week_ending].strftime('%Y-01-01')
        results = DB.fetch( "select sum(hours.quantity * rates.amount * (time_periods.#{column_name}/100)) as total from hours, rates, time_periods, payrolls where hours.payroll_id = payrolls.id AND hours.rate_id = rates.id AND rates.time_period_id = time_periods.id AND employee_id = ? AND payroll_id IN (SELECT id FROM payrolls WHERE week_ending >= ? AND week_ending <= ?)", @employee[:id], ytd_start, @payroll[:week_ending] ).first
        ytd_annuity = results[:total]

        table_data = []
        table_data << [{:content => "Annuity", :size => 10, :align => :center, :background_color => "D0D0D0", :colspan => 2}]
        table_data << [{:content => "Current Rate:", :size => 10, :align => :right, :background_color => "D0D0D0"}, {:content => sprintf("%.2f%%", current_annuity_rate), :size => 10, :align => :left}]
        table_data << [{:content => "Contribution This Time Period:", :size => 10, :align => :right, :background_color => "D0D0D0"}, {:content => display_as_currency(total_earnings*(current_annuity_rate/100)), :size => 10, :align => :left}]
        table_data << [{:content => "Contributions month-to-date:", :size => 10, :align => :right, :background_color => "D0D0D0"}, {:content => display_as_currency(mtd_annuity), :size => 10, :align => :left}]      
        table_data << [{:content => "Contributions year-to-date:", :size => 10, :align => :right, :background_color => "D0D0D0"}, {:content => display_as_currency(ytd_annuity), :size => 10, :align => :left}]      
        table( table_data,
          :cell_style => {
            :padding => 3,
            :border_color => "666666"
          },
          :width => 3.25.in,
        )
      
      
        move_down 10

        float do
          indent 3.75.in do
            # pension fund
            results = DB.fetch( "SELECT DISTINCT pension_rate FROM time_periods WHERE begins <= ? AND ends >= ?", @payroll[:week_ending], @payroll[:week_ending]).first
            current_pension_rate = results[:pension_rate]

            ytd_start = @payroll[:week_ending].strftime('%Y-01-01')
            results = DB.fetch( "select sum(hours.quantity * rates.amount * (time_periods.pension_rate/100)) as total from hours, rates, time_periods, payrolls where hours.payroll_id = payrolls.id AND hours.rate_id = rates.id AND rates.time_period_id = time_periods.id AND employee_id = ? AND payroll_id IN (SELECT id FROM payrolls WHERE week_ending >= ? AND week_ending <= ?)", @employee[:id], ytd_start, @payroll[:week_ending] ).first
            ytd_pension = results[:total]
            
            table_data = []
            table_data << [{:content => "Pension Fund", :size => 10, :align => :center, :background_color => "D0D0D0", :colspan => 2}]
            table_data << [{:content => "Current Rate:", :size => 10, :align => :right, :background_color => "D0D0D0"}, {:content => sprintf("%.2f%%", current_pension_rate), :size => 10, :align => :left}]
            table_data << [{:content => "Contribution This Time Period:", :size => 10, :align => :right, :background_color => "D0D0D0"}, {:content => display_as_currency(total_earnings*(current_pension_rate/100)), :size => 10, :align => :left}]
            table_data << [{:content => "Contributions YTD:", :size => 10, :align => :right, :background_color => "D0D0D0"}, {:content => display_as_currency(ytd_pension), :size => 10, :align => :left}]      
            table( table_data,
              :cell_style => {
                :padding => 3,
                :border_color => "666666"
              },
              :width => 3.25.in,
            )
          end
        end
        
        # welfare fund
        results = DB.fetch( "SELECT DISTINCT welfare_rate FROM time_periods WHERE begins <= ? AND ends >= ?", @payroll[:week_ending], @payroll[:week_ending]).first
        current_welfare_rate = results[:welfare_rate]

        ytd_start = @payroll[:week_ending].strftime('%Y-01-01')
        results = DB.fetch( "select sum(hours.quantity * rates.amount * (time_periods.welfare_rate/100)) as total from hours, rates, time_periods, payrolls where hours.payroll_id = payrolls.id AND hours.rate_id = rates.id AND rates.time_period_id = time_periods.id AND employee_id = ? AND payroll_id IN (SELECT id FROM payrolls WHERE week_ending >= ? AND week_ending <= ?)", @employee[:id], ytd_start, @payroll[:week_ending] ).first
        ytd_welfare = results[:total]
        
        table_data = []
        table_data << [{:content => "Welfare Fund", :size => 10, :align => :center, :background_color => "D0D0D0", :colspan => 2}]
        table_data << [{:content => "Current Rate:", :size => 10, :align => :right, :background_color => "D0D0D0"}, {:content => sprintf("%.2f%%", current_welfare_rate), :size => 10, :align => :left}]
        table_data << [{:content => "Contribution This Time Period:", :size => 10, :align => :right, :background_color => "D0D0D0"}, {:content => display_as_currency(total_earnings*(current_welfare_rate/100)), :size => 10, :align => :left}]
        table_data << [{:content => "Contributions YTD:", :size => 10, :align => :right, :background_color => "D0D0D0"}, {:content => display_as_currency(ytd_welfare), :size => 10, :align => :left}]      
        table( table_data,
          :cell_style => {
            :padding => 3,
            :border_color => "666666"
          },
          :width => 3.25.in,
        )
        
      end
      
    end
    
    class InvalidPayrollID < StandardError; end  
    class InvalidEmployeeID < StandardError; end  
    
  end
end
