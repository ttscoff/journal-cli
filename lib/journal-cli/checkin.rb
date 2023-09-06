module Journal
  # Main class
  class Checkin
    attr_reader :key, :date, :data, :config, :journal, :title, :output

    def initialize
      config = File.expand_path('~/.config/journal/journals.yaml')
      raise StandardError, 'No journals configured' unless File.exist?(config)

      @config = YAML.load(IO.read(config))
    end

    def start(journal, date)
      @key = journal
      @output = []
      @date = date

      raise StandardError, "No journal with key #{@key} found" unless @config['journals'].key? @key

      @journal = @config['journals'][@key]

      @data = {}
      meridian = @date.hour < 13 ? 'AM' : 'PM'
      @title = @journal['title'].sub(/%M/, meridian)
    end

    def title(string)
      @output << "\n## #{string}\n" unless string.nil?
    end

    def header(string)
      @output << "\n##### #{string}\n" unless string.nil?
    end

    def section(string)
      @output << "\n###### #{string}\n" unless string.nil?
    end

    def newline
      @output << "\n"
    end

    def hr
      @output << "\n---\n"
    end

    def ask_question(q)
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

      res
    end

    def go
      results = Data.new(@journal['questions'])
      @journal['sections'].each do |s|
        results[s['key']] = {
          title: s['title'],
          answers: {}
        }

        s['questions'].each do |q|
          if q['key'] =~ /\./
            res = results[s['key']][:answers]
            keys = q['key'].split(/\./)
            keys.each_with_index do |key, i|
              next if i == keys.count - 1

              res[key] = {} unless res.key?(key)
              res = res[key]
            end

            res[keys.last] = ask_question(q)
          else
            results[s['key']][:answers][q['key']] = ask_question(q)
          end
        end
      end

      @data = results

      if @journal['dayone']
        cmd = ['dayone2']
        cmd << %(-j "#{@journal['journal']}") if @journal.key?('journal')
        cmd << %(-t #{@journal['tags'].join(' ')}) if @journal.key?('tags')
        cmd << %(-date "#{@date.strftime('%Y-%m-%d %I:%M %p')}")
        `echo #{Shellwords.escape(to_markdown(yaml: false, title: true))} | #{cmd.join(' ')} -- new`
      end

      if @journal['markdown']
        if @journal['markdown'] =~ /^da(y|ily)/
          dir = File.expand_path("~/.local/share/journal/entries/#{@key}")
          FileUtils.mkdir_p(dir) unless File.directory?(dir)
          filename = "#{@date.strftime('%Y-%m-%d')}.md"
          target = File.join(dir, filename)
          if File.exist? target
            File.open(target, 'a') { |f| f.puts to_markdown(yaml: false, title: true, date: false, time: true) }
          else
            File.open(target, 'w') { |f| f.puts to_markdown(yaml: true, title: true, date: false, time: true) }
          end
        elsif @journal['markdown'] =~ /^(ind|separate)/
          dir = File.expand_path("~/.local/share/journal/entries/#{@key}")
          FileUtils.mkdir_p(dir) unless File.directory?(dir)
          filename = @date.strftime('%Y-%m-%d_%H:%M.md')
          File.open(File.join(dir, filename), 'w') { |f| f.puts to_markdown(yaml: true, title: true) }
        else
          dir = File.expand_path('~/.local/share/journal/entries/')
          FileUtils.mkdir_p(dir) unless File.directory?(dir)
          filename = "#{@key}.md"
          File.open(File.join(dir, filename), 'a') do |f|
            f.puts
            f.puts "## #{@title} #{@date.strftime('%x %X')}"
            f.puts
            f.puts to_markdown(yaml: false, title: false)
          end
        end
      end

      save_data
    end

    def print_answer(prompt, type, key, data)
      case type
      when /^(weather|forecast)/
        header prompt
        @output << data[key].to_markdown
        hr
      when /^(int|num)/
        @output << "#{prompt}: #{data[key]}  " unless data[key].nil?
      else
        unless data[key].strip.empty?
          header prompt
          @output << data[key]
        end
        hr
      end
    end

    def to_markdown(yaml: false, title: false, date: false, time: false)
      @output = []

      if yaml
        @output << <<~EOYAML
          ---
          title: #{@title}
          date: #{@date.strftime('%x %X')}
          ---

        EOYAML
      end

      if title
        if date || time
          fmt = ''
          fmt += '%x' if date
          fmt += '%X' if time
          title "#{@title} #{@date.strftime(fmt)}"
        else
          title @title
        end
      end

      @journal['sections'].each do |s|
        section s['title']

        s['questions'].each do |q|
          if q['key'] =~ /\./
            res = @data[s['key']][:answers].dup
            keys = q['key'].split(/\./)
            keys.each_with_index do |key, i|
              next if i == keys.count - 1

              res = res[key]
            end
            print_answer(q['prompt'], q['type'], keys.last, res)
          else
            print_answer(q['prompt'], q['type'], q['key'], @data[s['key']][:answers])
          end
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
        v[:answers].each do |q, a|
          if a.is_a? Hash
            output[q] = {}
            a.each do |key, value|
              output[q][key] = case value.class.to_s
                      when /Weather/
                        { 'high' => value.data[:high], 'low' => value.data[:low], 'condition' => value.data[:condition] }
                      else
                        value
                      end
            end
          else
            output[q] = a
          end
        end
      end
      data << { 'date' => date, 'data' => output }
      File.open(db, 'w') { |f| f.puts JSON.pretty_generate(data) }
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
      return output.join("\n") if line.strip.empty?

      output << line
      output << get_lines(add_prompt, add_prompt: add_prompt) if add_prompt
      output.join("\n")
    end
  end
end
