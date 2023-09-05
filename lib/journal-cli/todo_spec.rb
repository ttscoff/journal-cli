# frozen_string_literal: true

RSpec.describe Journal::Todo do
  subject(:todo) { Journal::Todo.new }

  describe ".todo" do
    it "returns todo" do
      expect(todo.todo).to be "TODO"
    end
  end
end
