# frozen_string_literal: true

module Journal
  # Individual question
  class Question
    attr_reader :key, :type, :min, :max, :prompt, :secondary_prompt, :gum, :condition

    ##
    ## Initializes the given question.
    ##
    ## @param      question  [Hash] The question with key, prompt, and type, optionally min and max
    ##
    ## @return     [Question] the question object
    ##
    def initialize(question)
      @key = question["key"]
      @type = question["type"]
      @min = question["min"]&.to_i || 1
      @max = question["max"]&.to_i || 5
      @prompt = question["prompt"] || nil
      @secondary_prompt = question["secondary_prompt"] || nil
      @gum = TTY::Which.exist?("gum")
      @condition = question.key?("condition") ? question["condition"].parse_condition : true
    end

    ##
    ## Ask the question, prompting for input based on type
    ##
    ## @return     [Number, String] the response based on @type
    ##
    def ask(condition)
      return nil if @prompt.nil?

      return nil unless @condition && condition

      res = case @type
            when /^int/i
              read_number(integer: true)
            when /^(float|num)/i
              read_number
            when /^(text|string|line)/i
              read_line
            when /^(weather|forecast)/i
              Weather.new(Journal.config["weather_api"], Journal.config["zip"], Journal.config["temp_in"])
            when /^multi/i
              read_lines
            when /^(date|time)/i
              read_date
            end
      Journal.notify("{dw}#{prompt}: {dy}#{res}{x}".x)
      res
    end

    private

    ##
    ## Read a numeric entry using gum or TTY::Reader
    ##
    ## @param      [Boolean] integer  Round result to nearest integer
    ##
    ## @return     [Number] integer response
    ##
    ##
    def read_number(integer: false)
      Journal.notify("{by}#{@prompt} {xc}({bw}#{@min}{xc}-{bw}#{@max}{xc})")

      res = @gum ? read_number_gum : read_line_tty

      res = integer ? res.to_f.round : res.to_f

      res = read_number if res < @min || res > @max
      res
    end

    def read_date(prompt: nil)
      prompt ||= @prompt
      Journal.notify("{by}#{prompt} (natural language)")
      line = @gum ? read_line_gum(prompt) : read_line_tty
      Chronic.parse(line)
    end

    ##
    ## Reads a line.
    ##
    ## @param      prompt  [String] If not nil, will trigger
    ##                     asking for a secondary response
    ##                     until a blank entry is given
    ##
    ## @return     [String] the single-line response
    ##
    def read_line(prompt: nil)
      output = []
      prompt ||= @prompt
      Journal.notify("{by}#{prompt}")

      line = @gum ? read_line_gum(prompt) : read_line_tty
      return output.join("\n") if /^ *$/.match?(line)

      output << line
      output << read_line(prompt: @secondary_prompt) unless @secondary_prompt.nil?
      output.join("\n").strip
    end

    ##
    ## Reads multiple lines.
    ##
    ## @param      prompt  [String] if not nil, will trigger
    ##                     asking for a secondary response
    ##                     until a blank entry is given
    ##
    ## @return     [String] the multi-line response
    ##
    def read_lines(prompt: nil)
      output = []
      prompt ||= @prompt
      Journal.notify("{by}#{prompt} {c}({bw}CTRL-d{c} to save)'")
      line = @gum ? read_multiline_gum(prompt) : read_mutliline_tty
      return output.join("\n") if line.strip.empty?

      output << line
      output << read_lines(prompt: @secondary_prompt) unless @secondary_prompt.nil?
      output.join("\n").strip
    end

    ##
    ## Read a numeric entry using gum
    ##
    ## @param      [Boolean] integer  Round result to nearest integer
    ##
    ## @return     [Number] integer response
    ##
    ##
    def read_number_gum
      trap("SIGINT") { exit! }
      res = `gum input --placeholder "#{@min}-#{@max}"`.strip
      return nil if res.strip.empty?

      res
    end

    ##
    ## Read a single line entry using TTY::Reader
    ##
    ## @param      [Boolean] integer  Round result to nearest integer
    ##
    ## @return     [Number] integer response
    ##
    def read_line_tty
      trap("SIGINT") { exit! }
      reader = TTY::Reader.new
      res = reader.read_line(">> ")
      return nil if res.strip.empty?

      res
    end

    ##
    ## Read a single line entry using gum
    ##
    ## @param      [Boolean] integer  Round result to nearest integer
    ##
    ## @return     [Number] integer response
    ##
    def read_line_gum(prompt)
      trap("SIGINT") { exit! }
      `gum input --placeholder "#{prompt} (blank to end answer)"`
    end

    ##
    ## Read a multiline entry using TTY::Reader
    ##
    ## @return     [string] multiline input
    ##
    def read_mutliline_tty
      trap("SIGINT") { exit! }
      reader = TTY::Reader.new
      res = reader.read_multiline
      res.join("\n")
    end

    ##
    ## Read a multiline entry using gum
    ##
    ## @return     [string] multiline input
    ##
    def read_multiline_gum(prompt)
      trap("SIGINT") { exit! }
      `gum write --placeholder "#{prompt}" --width 80 --char-limit 0`
    end
  end
end
