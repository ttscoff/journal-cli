# frozen_string_literal: true

module Journal
  class Weather
    attr_reader :data

    def initialize(api, zip)
      res = `curl -SsL 'http://api.weatherapi.com/v1/forecast.json?key=#{api}&q=#{zip}&aqi=no'`
      data = JSON.parse(res)

      raise StandardError, 'invalid JSON response' if data.nil?

      raise StandardError, 'missing conditions' unless data['current']

      curr_temp = data['current']['temp_f']
      curr_condition = data['current']['condition']['text']

      raise StandardError, 'mising forecast' unless data['forecast']

      forecast = data['forecast']['forecastday'][0]

      day = forecast['date']
      high = forecast['day']['maxtemp_f']
      low = forecast['day']['mintemp_f']
      condition = forecast['day']['condition']['text']

      hours = forecast['hour']
      temps = [
        { temp: hours[8]['temp_f'], condition: hours[8]['condition']['text'] },
        { temp: hours[10]['temp_f'], condition: hours[10]['condition']['text'] },
        { temp: hours[12]['temp_f'], condition: hours[12]['condition']['text'] },
        { temp: hours[14]['temp_f'], condition: hours[14]['condition']['text'] },
        { temp: hours[16]['temp_f'], condition: hours[16]['condition']['text'] },
        { temp: hours[18]['temp_f'], condition: hours[18]['condition']['text'] },
        { temp: hours[19]['temp_f'], condition: hours[20]['condition']['text'] }
      ]

      @data = {
        day: day,
        high: high,
        low: low,
        temp: curr_temp,
        condition: condition,
        current_condition: curr_condition,
        temps: temps
      }
    end

    def to_data
      {
        high: high,
        low: low,
        condition: curr_condition
      }
    end

    def current
      "#{@data[:temp]} and #{@data[:current_condition]}"
    end

    def forecast
      "#{@data[:condition]} #{@data[:high]}/#{@data[:low]}"
    end

    def to_s
      "#{@data[:temp].round} and #{@data[:current_condition]} (#{@data[:high].round}/#{@data[:low].round})"
    end

    def to_markdown
      output = []

      output << "Forecast for #{@data[:day]}: #{forecast}  "
      output << "Currently: #{current}"
      output << ''

      # Hours
      hours_text = %w[8am 10am 12pm 2pm 4pm 6pm 8pm]
      step_out = ['|']
      @data[:temps].each_with_index do |_h, i|
        width = @data[:temps][i][:condition].length + 1
        step_out << format("%#{width}s |", hours_text[i])
      end

      output << step_out.join('')

      # table separator
      step_out = ['|']
      @data[:temps].each do |temp|
        width = temp[:condition].length + 1
        step_out << "#{'-' * width}-|"
      end

      output << step_out.join('')

      # Conditions
      step_out = ['|']
      @data[:temps].each do |temp|
        step_out << format(' %s |', temp[:condition])
      end

      output << step_out.join('')

      # Temps
      step_out = ['|']
      @data[:temps].each do |temp|
        width = temp[:condition].length + 1
        step_out << format("%#{width}s |", temp[:temp])
      end

      output << step_out.join('')

      output.join("\n")
    end
  end
end
