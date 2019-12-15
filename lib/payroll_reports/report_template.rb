module PayrollReports
  class ReportTemplate
    include Prawn::View

    def initialize
      font "/Library/Fonts/Arial.ttf", :size => 10

      header
      content

    end
    
    def header
      # build first page header
      header_height = 1.1.in
      bounding_box( [0, bounds.top], :width => 1.in, :height => header_height) do 
        image "tpu.jpg", :fit => [bounds.right, bounds.top]
      end

      bounding_box( [bounds.right-1.in, bounds.top], :width => 1.in, :height => header_height) do 
        image "iatse.jpg", :fit => [bounds.right, bounds.top]
      end
  
      padding = 0.1.in
      bounding_box( [0+header_height+padding, bounds.top-padding], :width => bounds.right-2.in-2*padding, :height => header_height-2*padding) do
        text title, :align => :center, :size => 18
        text heading, :align => :center, :size => 14
        
        
        if headers.nil?
          table_data = []
          headers.each do |key,value|
            table_data << [
              {:content => key.empty? ? '' : key + ":", :size => 10, :align => :right},
              {:content => value, :size => 10, :align => :left}
            ]
          end
          
          table(
            table_data, 
            :cell_style => {
              :padding => 1,
              :borders => []
            }
          )
          
        end
        
      end

      move_cursor_to bounds.top-header_height
      stroke_horizontal_rule
    end

    def document
      @my_prawn_doc ||= Prawn::Document.new(page_size: 'LETTER', page_layout: :portrait, left_margin: 0.25.in, right_margin: 0.25.in, top_margin: 0.25.in, bottom_margin: 1.25.in)
    end
    
    def title
      "<default title>"
    end
    
    def heading
      "<default heading>"
    end
    
    def generate_qr_code(string, mode: :alphanumeric, size: 1)
      begin
        qrcode = RQRCode::QRCode.new(string, :size => size, :level => :h, :mode => mode)
      rescue RQRCodeCore::QRCodeRunTimeError
        qrcode = RQRCode::QRCode.new(string)
      end
      png = qrcode.as_png(
                resize_exactly_to: 86,
                fill: 'white',
                color: 'black',
                border_modules: 0,
                module_px_size: 6,
                )
            
      output = Tempfile.new
      output.write png.to_s
      output.close
      return output
    end
    
    def headers
      nil
    end
    
    def content
    end
    
    def footer

      # stroke all page bounds in red at end
      page_count.times do |i|
        go_to_page i
        stroke_color "ff0000"
#        stroke_bounds
        stroke_color "000000"
      end
        
#      number_pages "\nOrigin: #{self.class}", { :start_count_at => 0, :page_filter => :all, :at => [0+1.25.in, 0-0.1.in], :align => :left, :size => 10 }
      number_pages "Page <page> of <total>\nGenerated: #{Time.now.strftime '%Y-%M-%d %H:%M:%S'}", { :start_count_at => 0, :page_filter => :all, :at => [bounds.right-3.in, bounds.bottom-0.65.in], :align => :right, :size => 10 }

      # insert qr code
      if qr_code
        begin
          qr_code_file = generate_qr_code( qr_code )
        rescue RQRCodeCore::QRCodeArgumentError
          qr_code_file = generate_qr_code( qr_code, mode: :byte_8bit)
        end
        repeat :all do
         # footer
           image qr_code_file.path, :at => [bounds.left+0.05.in, bounds.bottom-0.05.in], :fit => [0.9.in, 0.9.in]
        end
      end
    end
    
    def save_as(filename)
      footer
      super
    end
    
    def display_as_currency(money)
      sprintf('%.2f', money)
    end

  end
end

