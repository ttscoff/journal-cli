# frozen_string_literal: true

require 'time'
require 'shellwords'
require 'json'
require 'yaml'
require 'chronic'
require 'fileutils'

require 'tty-which'
require 'tty-reader'
require_relative 'journal-cli/version'
require_relative 'journal-cli/color'
require_relative 'journal-cli/string'
require_relative 'journal-cli/data'
require_relative 'journal-cli/weather'
require_relative 'journal-cli/checkin'
require_relative 'journal-cli/sections'
require_relative 'journal-cli/section'
require_relative 'journal-cli/question'

# Main Journal module
module Journal
  class << self
    attr_accessor :date

    def notify(string, debug: false, exit_code: nil)
      if debug
        $stderr.puts "{dw}#{string}{x}".x
      else
        $stderr.puts "#{string}{x}".x
      end

      Process.exit exit_code unless exit_code.nil?
    end

    def config
      unless @config
        config = File.expand_path('~/.config/journal/journals.yaml')
        unless File.exist?(config)
          default_config = {
            'weather_api' => 'XXXXXXXXXXXXXXXXXx',
            'weather_deg' => 'F',
            'zip' => 'XXXXX',
            'entries_folder' => '~/.local/share/journal/',
            'journals' => {
              'demo' => {
                'dayone' => false,
                'markdown' => 'single',
                'title' => '5-minute checkin',
                'entries_folder' => '~/.local/share/journal/',
                'sections' => [
                  { 'title' => 'Quick checkin',
                    'key' => 'checkin',
                    'questions' => [
                      { 'prompt' => 'What\'s happening?', 'key' => 'journal', 'type' => 'multiline' }
                    ] }
                ]
              }
            }
          }
          File.open(config, 'w') { |f| f.puts(YAML.dump(default_config)) }
          puts "New configuration written to #{config}, please edit."
          Process.exit 0
        end
        @config = YAML.load(IO.read(config))

        if @config['journals'].key?('demo')
          Journal.notify("{br}Demo journal detected, please edit the configuration file at {bw}#{config}", exit_code: 1)
        end
      end

      @config
    end
  end
end
