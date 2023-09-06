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
        unless File.exist?(config)
          default_config = {
            'weather_api' => 'XXXXXXXXXXXXXXXXXx',
            'zip' => 'XXXXX',
            'journals' => {
              'demo' => {
                'dayone' => false,
                'markdown' => 'single',
                'title' => '5-minute checkin',
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
          puts "Demo journal detected, please edit the configuration file at #{config}"
          Process.exit 1
        end
      end

      @config
    end
  end
end
