# frozen_string_literal: true

module Journal
  # Individual question
  class Question
    attr_reader :key, :type, :min, :max, :prompt, :secondary_prompt

    ##
    ## Initializes the given question.
    ##
    ## @param      question  [Hash] The question with key, prompt, and type, optionally min and max
    ##
    ## @return     [Question] the question object
    ##
    def initialize(question)
      @key = question['key']
      @type = question['type']
      @min = question['min']&.to_i || 1
      @max = question['max']&.to_i || 5
      @prompt = question['prompt'] || nil
      @secondary_prompt = question['secondary_prompt'] || nil
    end

    ##
    ## Ask the question, prompting for input based on type
    ##
    ## @return     [Number, String] the response based on @type
    ##
    def ask
      case @type
      when /^(int|num)/i
        read_number
      when /^(text|string|line)/i
        read_line
      when /^(weather|forecast)/i
        Weather.new(Journal.config['weather_api'], Journal.config['zip'])
      when /^multi/
        read_lines
      else
        nil
      end
    end

    private

    ##
    ## Read a numeric entry
    ##
    ## @return     [Number] integer response
    ##
    def read_number
      Journal.notify("{by}#{@prompt} {c}({bw}#{@min}{c}-{bw}#{@max})")
      res = `gum input --placeholder "#{@prompt} (#{@min}-#{@max})"`.strip
      return nil if res.strip.empty?

      res = res.to_i

      res = read_number if res < @min || res > @max
      res
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
      Journal.notify("{by}#{prompt.nil? ? @prompt : @secondary_prompt}")

      line = `gum input --placeholder "#{@prompt} (blank to end editing)"`
      return output.join("\n") if line =~ /^ *$/

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
      Journal.notify("{by}#{prompt.nil? ? @prompt : @secondary_prompt} {c}({bw}CTRL-d{c} to save)'")
      line = `gum write --placeholder "#{prompt}" --width 80 --char-limit 0`
      return output.join("\n") if line.strip.empty?

      output << line
      output << read_lines(prompt: @secondary_prompt) unless @secondary_prompt.nil?
      output.join("\n").strip
    end
  end
end
