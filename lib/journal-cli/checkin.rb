module Journal
  # Main class
  class Checkin
    attr_reader :key, :date, :data, :config, :journal, :sections, :title, :output

    def initialize(journal, date)
      @key = journal
      @output = []
      @date = date
      @date.localtime

      raise StandardError, "No journal with key #{@key} found" unless Journal.config['journals'].key? @key

      @journal = Journal.config['journals'][@key]
      @sections = Sections.new(@journal['sections'])

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

    def go
      @sections.each { |key, section| @data[key] = section }

      save_data
      save_day_one_entry if @journal['dayone']

      return unless @journal['markdown']

      case @journal['markdown']
      when /^da(y|ily)/
        save_daily_markdown
      when /^(ind|sep)/
        save_individual_markdown
      else
        save_single_markdown
      end
    end

    def save_day_one_entry
      cmd = ['dayone2']
      cmd << %(-j "#{@journal['journal']}") if @journal.key?('journal')
      cmd << %(-t #{@journal['tags'].join(' ')}) if @journal.key?('tags')
      cmd << %(-date "#{@date.strftime('%Y-%m-%d %I:%M %p')}")
      `echo #{Shellwords.escape(to_markdown(yaml: false, title: true))} | #{cmd.join(' ')} -- new`
      Journal.notify('{bg}Entered one entry into Day One')
    end

    def save_single_markdown
      dir = if @journal.key?('entries_folder')
              File.join(File.expand_path(@journal['entries_folder']), 'entries')
            elsif Journal.config.key?('entries_folder')
              File.join(File.expand_path(Journal.config['entries_folder']), @key)
            else
              File.expand_path("~/.local/share/journal/#{@key}/entries")
            end

      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      filename = "#{@key}.md"
      @date.localtime
      target = File.join(dir, filename)
      File.open(target, 'a') do |f|
        f.puts
        f.puts "## #{@title} #{@date.strftime('%x %X')}"
        f.puts
        f.puts to_markdown(yaml: false, title: false)
      end
      Journal.notify "{bg}Added new entry to {bw}#{target}"
    end

    def save_daily_markdown
      dir = if @journal.key?('entries_folder')
              File.join(File.expand_path(@journal['entries_folder']), 'entries')
            elsif Journal.config.key?('entries_folder')
              File.join(File.expand_path(Journal.config['entries_folder']), @key)
            else
              File.join(File.expand_path("~/.local/share/journal/#{@key}/entries"))
            end

      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      @date.localtime
      filename = "#{@key}_#{@date.strftime('%Y-%m-%d')}.md"
      target = File.join(dir, filename)
      if File.exist? target
        File.open(target, 'a') { |f| f.puts to_markdown(yaml: false, title: true, date: false, time: true) }
      else
        File.open(target, 'w') { |f| f.puts to_markdown(yaml: true, title: true, date: false, time: true) }
      end
      Journal.notify "{bg}Saved daily Markdown to {bw}#{target}"
    end

    def save_individual_markdown
      dir = if @journal.key?('entries_folder')
              File.join(File.expand_path(@journal['entries_folder']), 'entries')
            elsif Journal.config.key?('entries_folder')
              File.join(File.expand_path(Journal.config['entries_folder']), @key,
                        'entries')
            else
              File.join(File.expand_path('~/.local/share/journal'), @key, 'entries')
            end

      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      @date.localtime
      filename = @date.strftime('%Y-%m-%d_%H:%M.md')
      target = File.join(dir, filename)
      File.open(target, 'w') { |f| f.puts to_markdown(yaml: true, title: true) }
      puts "Saved new entry to #{target}"
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

    def weather_to_yaml(answers)
      data = {}
      answers.each do |k, v|
        case v.class.to_s
        when /Hash/
          data[k] = weather_to_yaml(v)
        when /Weather/
          data[k] = v.to_s
        else
          data[k] = v
        end
      end
      data
    end

    def to_markdown(yaml: false, title: false, date: false, time: false)
      @output = []

      if yaml
        @date.localtime
        yaml_data = { 'title' => @title, 'date' => @date.strftime('%x %X')}
        @data.each do |key, data|
          yaml_data = yaml_data.merge(weather_to_yaml(data.answers))
        end

        @output << YAML.dump(yaml_data).strip
        @output << '---'
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

      @sections.each do |key, section|
        answers = section.answers
        section section.title

        section.questions.each do |question|
          if question.key =~ /\./
            res = section.answers.dup
            keys = question.key.split(/\./)
            keys.each_with_index do |key, i|
              next if i == keys.count - 1

              res = res[key]
            end
            print_answer(question.prompt, question.type, keys.last, res)
          else
            print_answer(question.prompt, question.type, question.key, section.answers)
          end
        end
      end

      @output.join("\n")
    end

    def save_data
      @date.localtime
      dir = if @journal.key?('entries_folder')
              File.expand_path(@journal['entries_folder'])
            elsif Journal.config.key?('entries_folder')
              File.expand_path(Journal.config['entries_folder'])
            else
              File.expand_path('~/.local/share/journal')
            end
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      db = File.join(dir, "#{@key}.json")
      data = if File.exist?(db)
               JSON.parse(IO.read(db))
             else
               []
             end
      date = @date.utc
      output = {}

      @data.each do |jk, journal|
        output[jk] = {}
        journal.answers.each do |k, v|
          if v.is_a? Hash
            v.each do |key, value|
              result = case value.class.to_s
                       when /Weather/
                         {
                           'high' => value.data[:high],
                           'low' => value.data[:low],
                           'condition' => value.data[:condition]
                         }
                       else
                         value
                       end
              if jk == k
                output[jk][key] = result
              else
                output[jk][k] ||= {}
                output[jk][k][key] = result
              end
            end
          elsif jk == k
            output[jk] = v
          else
            output[jk][k] = v
          end
        end
      end
      data << { 'date' => date, 'data' => output }
      data.map! do |d|
        {
          'date' => d['date'].is_a?(String) ? Time.parse(d['date']) : d['date'],
          'data' => d['data']
        }
      end

      data.sort_by! { |e| e['date'] }

      File.open(db, 'w') { |f| f.puts JSON.pretty_generate(data) }
      Journal.notify "{bg}Saved {bw}#{db}"
    end
  end
end
