# frozen_string_literal: true

# String helpers
class ::String
  def parse_condition
    condition = dup
    time_rx = /(?<comp>[<>=]{1,2}|before|after) +(?<time>(?:noon|midnight|[0-9]+) *(?:am|pm)?)$/i
    return true unless condition =~ time_rx

    now = Journal.date
    m = condition.match(time_rx)
    time = Chronic.parse(m['time'])
    Journal.notify("{br}Invalid time string in question (#{m['time']})", exit_code: 4) unless time

    case m['comp']
    when /^<=$/
      now <= time
    when /^(<|bef)/i
      now < time
    when /^>=/
      now >= time
    when /^(>|aft)/i
      now > time
    end
    # TODO: Other condition types
  end
end
