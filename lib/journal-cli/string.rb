# frozen_string_literal: true

# String helpers
class ::String

  ##
  ## Parse and test a condition
  ##
  ## @return     [Boolean] whether test passed
  ##
  def parse_condition
    condition = dup
    time_rx = /(?<comp>[<>=]{1,2}|before|after) +(?<time>(?:noon|midnight|[0-9]+) *(?:am|pm)?)$/i
    return true unless condition&.match?(time_rx)

    now = Journal.date
    m = condition.match(time_rx)
    time = Chronic.parse(m["time"])
    now.localtime
    time.localtime
    time_of_day = Time.parse("#{now.strftime("%Y-%m-%d")} #{time.strftime("%H:%M")}")
    Journal.notify("{br}Invalid time string in question (#{m["time"]})", exit_code: 4) unless time

    case m["comp"]
    when /^<=$/
      now <= time_of_day
    when /^(<|bef)/i
      now < time_of_day
    when /^>=/
      now >= time_of_day
    when /^(>|aft)/i
      now > time_of_day
    end
    # TODO: Other condition types
  end
end
