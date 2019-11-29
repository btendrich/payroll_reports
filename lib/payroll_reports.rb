require "prawn"
require 'prawn/measurement_extensions'
require 'prawn/table'
require 'rqrcode'
require 'tempfile'
require 'sequel'

require "payroll_reports/version"
require "payroll_reports/report_template"
require "payroll_reports/weekly_summary"

DB = Sequel.connect(ENV['SEQUEL_URI'])

module PayrollReports
  class Error < StandardError; end
  # Your code goes here...
end
