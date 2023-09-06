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
    end

    def save_single_markdown
      dir = File.expand_path('~/.local/share/journal/entries/')
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
      puts "Saved #{target}"
    end

    def save_daily_markdown
      dir = File.expand_path("~/.local/share/journal/entries/#{@key}")
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      @date.localtime
      filename = "#{@date.strftime('%Y-%m-%d')}.md"
      target = File.join(dir, filename)
      if File.exist? target
        File.open(target, 'a') { |f| f.puts to_markdown(yaml: false, title: true, date: false, time: true) }
      else
        File.open(target, 'w') { |f| f.puts to_markdown(yaml: true, title: true, date: false, time: true) }
      end
      puts "Saved #{target}"
    end

    def save_individual_markdown
      dir = File.expand_path("~/.local/share/journal/entries/#{@key}")
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      @date.localtime
      filename = @date.strftime('%Y-%m-%d_%H:%M.md')
      target = File.join(dir, filename)
      File.open(target, 'w') { |f| f.puts to_markdown(yaml: true, title: true) }
      puts "Saved #{target}"
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
        @date.localtime
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
      db = File.expand_path("~/.local/share/journal/#{@key}.json")
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
            output[jk][k] = {}
            v.each do |key, value|
              output[jk][k][key] = case value.class.to_s
                               when /Weather/
                                 { 'high' => value.data[:high], 'low' => value.data[:low], 'condition' => value.data[:condition] }
                               else
                                 value
                               end
            end
          else
            output[jk][k] = v
          end
        end
      end
      data << { 'date' => date, 'data' => output }
      File.open(db, 'w') { |f| f.puts JSON.pretty_generate(data) }
    end
  end
end
