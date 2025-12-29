# frozen_string_literal: true

module FamilyMembersHelper
  def generation_label(generation)
    case generation
    when nil, 0
      "本人世代"
    when 1
      "親世代"
    when 2
      "祖父母世代"
    when -1
      "子世代"
    when -2
      "孫世代"
    else
      generation.positive? ? "#{generation}世代上" : "#{generation.abs}世代下"
    end
  end

  def generation_border_class(generation)
    case generation
    when nil, 0
      "border-blue-400"
    when 1, 2
      "border-purple-400"
    when -1
      "border-green-400"
    when -2
      "border-teal-400"
    else
      "border-gray-400"
    end
  end
end
