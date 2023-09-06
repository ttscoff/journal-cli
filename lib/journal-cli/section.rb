# frozen_string_literal: true

module Journal
  class Section
    attr_accessor :key, :title, :questions, :answers

    ##
    ## Initializes the given section.
    ##
    ## @param      section  [Hash] The section as defined in
    ##                      configuration
    ##
    ## @return     [Section] the configured section
    ##
    def initialize(section)
      @key = section['key']
      @title = section['title']
      @questions = section['questions'].map { |question| Question.new(question) }
      @answers = {}
      ask_questions
    end

    ##
    ## Ask the questions detailed in the 'questions' section of the configuration
    ##
    ## @return [Hash] the question responses
    ##
    def ask_questions
      @questions.each do |question|
        if question.key =~ /\./
          res = @answers
          keys = question.key.split(/\./)
          keys.each_with_index do |key, i|
            next if i == keys.count - 1

            res[key] = {} unless res.key?(key)
            res = res[key]
          end

          res[keys.last] = question.ask
        else
          @answers[question.key] = question.ask
        end
      end
    end
  end
end
