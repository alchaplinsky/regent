# frozen_string_literal: true

module Regent
  class Session
    include Concerns::Identifiable
    include Concerns::Durationable

    def initialize(agent)
      super()

      @agent = agent
      @spans = []
      @messages = []
      @start_time = nil
      @end_time = nil
    end

    attr_reader :id, :spans, :start_time, :end_time
    attr_accessor :messages

    def start
      @start_time = Time.now
    end

    def continue(type, options = {})
      @spans << Span.new(session: self, type: type, arguments: options)
      result = spans.last.execute
      result
    end

    def complete(type = nil, options = {})
      continue(type, options) if type

      @end_time = Time.now
      spans.last.output
    end

    def running?
      start_time && end_time.nil?
    end

    def result
      spans.last.output
    end

    def llm
      @agent.llm
    end
  end
end
