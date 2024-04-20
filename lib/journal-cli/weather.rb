# frozen_string_literal: true

module Journal
  class Weather
    attr_reader :data

    def initialize(api, zip, temp_in)
      Journal.date.localtime
      if Journal.date.strftime('%Y-%m-%d') == Time.now.strftime('%Y-%m-%d')
        res = `curl -SsL 'http://api.weatherapi.com/v1/forecast.json?key=#{api}&q=#{zip}&aqi=no'`
      else
        res = `curl -SsL 'http://api.weatherapi.com/v1/history.json?key=#{api}&q=#{zip}&aqi=no&dt=#{Journal.date.strftime('%Y-%m-%d')}'`
      end

      data = JSON.parse(res)

      raise StandardError, 'invalid JSON response' if data.nil?

      raise StandardError, 'missing forecast' unless data['forecast']

      temp_key = temp_in =~ /^c/ ? 'temp_c' : 'temp_f'

      if Journal.date.strftime('%Y-%m-%d') == Time.now.strftime('%Y-%m-%d')
        raise StandardError, 'missing conditions' unless data['current']

        curr_temp = data['current'][temp_key]
        curr_condition = data['current']['condition']['text']
      else
        time = Journal.date.strftime('%Y-%m-%d %H:00')
        hour = data['forecast']['forecastday'][0]['hour'].filter { |h| h['time'].to_s =~ /#{time}/ }.first
        curr_temp = hour[temp_key]
        curr_condition = hour['condition']['text']
      end

      forecast = data['forecast']['forecastday'][0]

      moon_phase = forecast['astro']['moon_phase']

      day = forecast['date']
      high = temp_in =~ /^c/ ? forecast['day']['maxtemp_c'] : forecast['day']['maxtemp_f']
      low = temp_in =~ /^c/ ? forecast['day']['mintemp_c'] : forecast['day']['mintemp_f']
      condition = forecast['day']['condition']['text']

      hours = forecast['hour']
      temps = [
        { temp: hours[8][temp_key], condition: hours[8]['condition']['text'] },
        { temp: hours[10][temp_key], condition: hours[10]['condition']['text'] },
        { temp: hours[12][temp_key], condition: hours[12]['condition']['text'] },
        { temp: hours[14][temp_key], condition: hours[14]['condition']['text'] },
        { temp: hours[16][temp_key], condition: hours[16]['condition']['text'] },
        { temp: hours[18][temp_key], condition: hours[18]['condition']['text'] },
        { temp: hours[19][temp_key], condition: hours[20]['condition']['text'] }
      ]

      @data = {
        day: day,
        high: high,
        low: low,
        temp: curr_temp,
        condition: condition,
        current_condition: curr_condition,
        temps: temps,
        moon_phase: moon_phase
      }
    end

    def to_data
      {
        high: @data[:high],
        low: @data[:low],
        condition: @data[:current_condition],
        moon_phase: @data[:moon_phase]
      }
    end

    def moon
      @data[:moon_phase]
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
      output << "Currently: #{current}  "
      output << "Moon Phase: #{moon}  "
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
