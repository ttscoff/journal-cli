# frozen_string_literal: true

RSpec.describe MakenewRbgem::Todo do
  subject(:todo) { MakenewRbgem::Todo.new }

  describe ".todo" do
    it "returns todo" do
      expect(todo.todo).to be "TODO"
    end
  end
end
