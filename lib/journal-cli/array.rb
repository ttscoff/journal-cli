# frozen_string_literal: true

class ::Array
  def shortest
    inject { |memo, word| memo.length < word.length ? memo : word }
  end

  def longest
    inject { |memo, word| memo.length > word.length ? memo : word }
  end
end
