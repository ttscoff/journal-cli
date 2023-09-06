# frozen_string_literal: true

require 'time'
require 'shellwords'
require 'json'
require 'yaml'
require 'chronic'
require 'fileutils'

require_relative 'journal-cli/version'
require_relative 'journal-cli/data'
require_relative 'journal-cli/weather'
require_relative 'journal-cli/checkin'
require_relative 'journal-cli/sections'
require_relative 'journal-cli/section'
require_relative 'journal-cli/question'

# Main Journal module
module Journal
  class << self
    def config
      unless @config
        config = File.expand_path('~/.config/journal/journals.yaml')
        raise StandardError, 'No journals configured' unless File.exist?(config)

        @config = YAML.load(IO.read(config))
      end

      @config
    end
  end
end
