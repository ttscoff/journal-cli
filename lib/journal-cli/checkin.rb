module Journal
  # Main class
  class Checkin
    attr_reader :key, :date, :data, :config, :journal, :sections, :title, :output

    ##
    ## Initialize a new checkin using a configured journal
    ##
    ## @param      journal  [Journal] The journal
    ##
    def initialize(journal)
      @key = journal
      @output = []
      @date = Journal.date
      @date.localtime

      raise StandardError, "No journal with key #{@key} found" unless Journal.config["journals"].key? @key

      @journal = Journal.config["journals"][@key]
      @sections = Sections.new(@journal["sections"])

      @data = {}
      meridian = (@date.hour < 13) ? "AM" : "PM"
      @title = @journal["title"].sub(/%M/, meridian)
    end

    ##
    ## Add a title (Markdown) to the output
    ##
    ## @param      string  [String] The string
    ##
    def add_title(string)
      @output << "\n## #{string}\n" unless string.nil?
    end

    ##
    ## Add a question header (Markdown) to the output
    ##
    ## @param      string  [String] The string
    ##
    def header(string)
      @output << "\n##### #{string}\n" unless string.nil?
    end

    ##
    ## Add a section header (Markdown) to the output
    ##
    ## @param      string  [String] The string
    ##
    def section(string)
      @output << "\n###### #{string}\n" unless string.nil?
    end

    ##
    ## Add a newline to the output
    ##
    def newline
      @output << "\n"
    end

    ##
    ## Add a horizontal rule (Markdown) to the output
    ##
    def hr
      @output << "\n* * * * * *\n"
    end

    ##
    ## Finalize the checkin, saving data to JSON, Day One,
    ## and Markdown as configured
    ##
    def go
      @sections.each { |key, section| @data[key] = section }

      save_data
      save_day_one_entry if @journal["dayone"]

      return unless @journal["markdown"]

      case @journal["markdown"]
      when /^da(y|ily)/
        save_daily_markdown
      when /^(ind|sep)/
        save_individual_markdown
      else
        save_single_markdown
      end
    end

    ##
    ## Launch Day One and quit if it wasn't running
    ##
    def launch_day_one
      # Launch Day One to ensure database is up-to-date
      # test if Day One is open
      @running = !`ps ax | grep "/MacOS/Day One" | grep -v grep`.strip.empty?
      # -g do not bring app to foreground
      # -j launch hidden
      `/usr/bin/open -gj -a "Day One"`
      sleep 3
    end

    ##
    ## Save journal entry to Day One using the command line tool
    ##
    def save_day_one_entry
      unless TTY::Which.exist?("dayone2")
        Journal.notify("{br}Day One CLI not installed, no Day One entry created")
        return
      end

      launch_day_one

      @date.localtime
      cmd = ["dayone2"]
      cmd << %(-j "#{@journal["journal"]}") if @journal.key?("journal")
      cmd << %(-t #{@journal["tags"].join(" ")}) if @journal.key?("tags")
      cmd << %(-date "#{@date.strftime("%Y-%m-%d %I:%M %p")}")
      `echo #{Shellwords.escape(to_markdown(yaml: false, title: true))} | #{cmd.join(" ")} -- new`
      Journal.notify("{bg}Entered one entry into Day One")

      # quit if it wasn't running
      `osascript -e 'tell app "Day One" to quit'` if !@running
    end

    ##
    ## Save entry to an existing Markdown file
    ##
    def save_single_markdown
      dir = if @journal.key?("entries_folder")
        File.join(File.expand_path(@journal["entries_folder"]), "entries")
      elsif Journal.config.key?("entries_folder")
        File.join(File.expand_path(Journal.config["entries_folder"]), @key)
      else
        File.expand_path("~/.local/share/journal/#{@key}/entries")
      end

      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      filename = "#{@key}.md"
      @date.localtime
      target = File.join(dir, filename)
      File.open(target, "a") do |f|
        f.puts
        f.puts "## #{@title} #{@date.strftime("%x %X")}"
        f.puts
        f.puts to_markdown(yaml: false, title: false)
      end
      Journal.notify "{bg}Added new entry to {bw}#{target}"
    end

    ##
    ## Save journal entry to daily Markdown file
    ##
    def save_daily_markdown
      dir = if @journal.key?("entries_folder")
        File.join(File.expand_path(@journal["entries_folder"]), "entries")
      elsif Journal.config.key?("entries_folder")
        File.join(File.expand_path(Journal.config["entries_folder"]), @key)
      else
        File.join(File.expand_path("~/.local/share/journal/#{@key}/entries"))
      end

      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      @date.localtime
      filename = "#{@key}_#{@date.strftime("%Y-%m-%d")}.md"
      target = File.join(dir, filename)
      if File.exist? target
        File.open(target, "a") { |f| f.puts to_markdown(yaml: false, title: true, date: false, time: true) }
      else
        File.open(target, "w") { |f| f.puts to_markdown(yaml: true, title: true, date: false, time: true) }
      end
      Journal.notify "{bg}Saved daily Markdown to {bw}#{target}"
    end

    ##
    ## Save journal entry to an new individual Markdown file
    ##
    def save_individual_markdown
      dir = if @journal.key?("entries_folder")
        File.join(File.expand_path(@journal["entries_folder"]), "entries")
      elsif Journal.config.key?("entries_folder")
        File.join(File.expand_path(Journal.config["entries_folder"]), @key,
          "entries")
      else
        File.join(File.expand_path("~/.local/share/journal"), @key, "entries")
      end

      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      @date.localtime
      filename = @date.strftime("%Y-%m-%d_%H%M.md")
      target = File.join(dir, filename)
      File.open(target, "w") { |f| f.puts to_markdown(yaml: true, title: true) }
      puts "Saved new entry to #{target}"
    end

    def print_answer(prompt, type, key, data)
      return if data.nil? || !data.key?(key) || data[key].nil?

      case type
      when /^(weather|forecast|moon)/
        header prompt
        @output << case type
        when /current$/
          data[key].current
        when /moon$/
          "Moon phase: #{data[key].moon}"
        else
          data[key].to_markdown
        end
      when /^(int|num)/
        @output << "#{prompt}: #{data[key]}  " unless data[key].nil?
      when /^date/
        @output << "#{prompt}: #{data[key].strftime("%Y-%m-%d %H:%M")}" unless data[key].nil?
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
        when /String/
          next
        when /Hash/
          data[k] = weather_to_yaml(v)
        when /Date/
          v.localtime
          data[k] = v.strftime("%Y-%m-%d %H:%M")
        when /Weather/
          data[k] = case k
          when /current$/
            v.current
          when /forecast$/
            data[k] = v.forecast
          when /moon(_?phase)?$/
            data[k] = v.moon
          else
            data[k] = v.to_s
          end
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
        yaml_data = {"title" => @title, "date" => @date.strftime("%x %X")}
        @data.each do |key, data|
          yaml_data = yaml_data.merge(weather_to_yaml(data.answers))
        end

        @output << YAML.dump(yaml_data).strip
        @output << "---"
      end

      if title
        if date || time
          fmt = ""
          fmt += "%x" if date
          fmt += "%X" if time
          add_title "#{@title} #{@date.strftime(fmt)}"
        else
          add_title @title
        end
      end

      @sections.each do |key, section|
        section section.title

        section.questions.each do |question|
          if /\./.match?(question.key)
            res = section.answers.dup
            keys = question.key.split(".")
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
      dir = if @journal.key?("entries_folder")
        File.expand_path(@journal["entries_folder"])
      elsif Journal.config.key?("entries_folder")
        File.expand_path(Journal.config["entries_folder"])
      else
        File.expand_path("~/.local/share/journal")
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
                case key
                when /current$/
                  {
                    "temp" => value.data[:temp],
                    "condition" => value.data[:current_condition]
                  }
                when /moon(_?phase)?$/
                  {
                    "phase" => value.data[:moon_phase]
                  }
                else
                  {
                    "high" => value.data[:high],
                    "low" => value.data[:low],
                    "condition" => value.data[:condition],
                    "moon_phase" => value.data[:moon_phase]
                  }
                end
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
      data << {"date" => date, "data" => output}
      data.map! do |d|
        {
          "date" => d["date"].is_a?(String) ? Time.parse(d["date"]) : d["date"],
          "data" => d["data"]
        }
      end

      data.sort_by! { |e| e["date"] }

      File.open(db, "w") { |f| f.puts JSON.pretty_generate(data) }
      Journal.notify "{bg}Saved {bw}#{db}"
    end
  end
end
