# frozen_string_literal: true

RSpec.describe Journal do
  it "has a version number" do
    expect(Journal::VERSION).not_to be nil
  end
end
