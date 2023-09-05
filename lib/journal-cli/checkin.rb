module Journal
# Main class
  class Checkin
    attr_reader :key, :date, :data, :config, :journal, :title, :output

    def initialize(journal, date)
      @key = journal
      @output = []
      @date = date

      config = File.expand_path('~/.config/journal/journals.yaml')
      raise StandardError, 'No journals configured' unless File.exist?(config)

      @config = YAML.load(IO.read(config))

      raise StandardError, "No journal with key #{@key} found" unless @config['journals'].key? @key

      @journal = @config['journals'][@key]

      @data = Data.new(@journal['questions'])
      meridian = @date.hour < 13 ? 'AM' : 'PM'
      @title = @journal['title'].sub(/%M/, meridian)
    end

    def header(string)
      @output << "\n## #{string}\n"
    end

    def newline
      @output << "\n"
    end

    def hr
      @output << "\n---\n"
    end

    def go
      results = Data.new(@journal['questions'])
      @journal['questions'].each do |q|
        res = case q['type']
              when /^(int|num)/i
                min = q['min'] || 1
                max = q['max'] || 5
                get_number(q['prompt'], min: min, max: max)
              when /^(text|string|line)/i
                puts q['prompt']
                add_prompt = q['secondary_prompt'] || nil
                get_line(q['prompt'], add_prompt: add_prompt)
              when /^(weather|forecast)/i
                Weather.new(@config['weather_api'], @config['zip'])
              when /^multi/
                puts q['prompt']
                add_prompt = q['secondary_prompt'] || nil
                get_lines(q['prompt'], add_prompt: add_prompt)
              end
        results[q['key']] = res
      end

      @data = results.to_data

      if @journal['dayone']
        cmd = ['dayone2']
        cmd << %(-j "#{@journal['journal']}")
        cmd << %(-t #{@journal['tags'].join(' ')})
        cmd << %(-date "#{@date.strftime('%Y-%m-%d %I:%M %p')}")
        `echo #{Shellwords.escape(to_markdown)} | #{cmd.join(' ')} -- new`
      end

      if @journal['markdown']
        dir = File.expand_path('~/.local/share/journal/entries')
        FileUtils.mkdir_p(dir) unless File.directory?(dir)
        if @journal['markdown'] =~ /^ind/
          filename = @date.strftime('%Y-%m-%d_%H:%M.md')
          File.open(File.join(dir, filename), 'w') { |f| f.puts to_markdown }
        else
          filename = "#{@key}.md"
          File.open(File.join(dir, filename), 'a') do |f|
            f.puts
            f.puts "#{@title} #{@date.strftime('%x %X')}"
            f.puts to_markdown
          end
        end
      end

      save_data
    end

    def to_markdown
      @output = []

      @output << "#{@title}\n"

      @journal['questions'].each do |q|
        case q['type']
        when /^(weather|forecast)/
          header q['prompt']
          @output << @data[q['key']].to_markdown
          hr
        when /^(int|num)/
          @output << "#{q['prompt']}: #{@data[q['key']]}" unless @data[q['key']].nil?
        else
          unless @data[q['key']].strip.empty?
            header q['prompt']
            @output << @data[q['key']]
          end
          hr
        end
      end

      @output.join("\n")
    end

    def save_data
      db = File.expand_path("~/.local/share/journal/#{@key}.json")
      data = if File.exist?(db)
               JSON.parse(IO.read(db))
             else
               []
             end
      date = @date.utc
      output = {}
      @data.each do |k, v|
        output[k] = case v.class.to_s
                    when /Weather/
                      { 'high' => v.data[:high], 'low' => v.data[:low], 'condition' => v.data[:condition] }
                    else
                      v
                    end
      end
      data << { 'date' => date, 'data' => output }
      File.open(db, 'w') { |f| f.puts data.to_json }
    end

    def get_number(prompt, min: 1, max: 5)
      puts "#{prompt} (#{min}-#{max})"
      res = `gum input --placeholder "#{prompt} (#{min}-#{max})"`.strip
      return nil if res.strip.empty?

      res = res.to_i

      res = get_number(prompt, min: min, max: max) if res < min || res > max
      res
    end

    def get_line(prompt, add_prompt: nil)
      output = []
      puts prompt
      line = `gum input --placeholder "#{prompt} (blank to end editing)"`
      return output.join("\n") if line =~ /^ *$/

      output << line
      output << get_line(add_prompt, add_prompt: add_prompt) if add_prompt
      output.join("\n")
    end

    def get_lines(prompt, add_prompt: nil)
      output = []
      line = `gum write --placeholder "#{prompt}" --width 80 --char-limit 0`
      return output.join("\n") if line =~ /^ *$/

      output << line
      output << get_lines(add_prompt, add_prompt: add_prompt) if add_prompt
      output.join("\n")
    end
  end
end
