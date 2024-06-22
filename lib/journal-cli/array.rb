# frozen_string_literal: true

##
## Array helpers
##
class ::Array
  ##
  ## Find the shortest element in an array of strings
  ##
  ## @return     [String] shortest element
  ##
  def shortest
    inject { |memo, word| (memo.length < word.length) ? memo : word }
  end

  ##
  ## Find the longest element in an array of strings
  ##
  ## @return     [String] longest element
  ##
  def longest
    inject { |memo, word| (memo.length > word.length) ? memo : word }
  end
end
