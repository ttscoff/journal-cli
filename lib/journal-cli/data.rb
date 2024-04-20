# frozen_string_literal: true

module Journal
  # Data handler
  class Data < Hash
    attr_reader :questions

    def initialize(questions)
      @questions = questions
      super
    end

    def to_data
      output = {}
      @questions.each do |q|
        output[q["key"]] = self[q["key"]]
      end
      output
    end
  end
end
