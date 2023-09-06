# frozen_string_literal: true

module Journal
  class Sections < Hash
    def initialize(sections)
      sections.each do |sect|
        section = Section.new(sect)
        self[section.key] = section
      end
      super
    end
  end
end
