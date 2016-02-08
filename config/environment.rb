# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

APP_VERSION = `git describe`.gsub("\n", "")

require "patient_service"
require "bantu_soundex"
require "bean"
require "csv"
