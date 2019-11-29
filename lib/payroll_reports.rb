require "payroll_reports/version"

require 'date'
require 'yaml'
require 'pp'
require 'logger'
require 'tempfile'
require 'fileutils'
require 'prawn'
require 'prawn/table'
require 'prawn/measurement_extensions'
require 'sequel'

module PayrollReports
  class Error < StandardError; end
  # Your code goes here...
end
