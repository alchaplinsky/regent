# frozen_string_literal: true

module Regent
  class LLM
    DEFAULT_RETRY_COUNT = 3
    PROVIDER_PATTERNS = {
      OpenAI: /^gpt-/,
      Gemini: /^gemini-/,
      Anthropic: /^claude-/
    }.freeze

    class ProviderNotFoundError < StandardError; end
    class APIKeyNotFoundError < StandardError; end
    class ApiError < StandardError; end

    def initialize(model, strict_mode: true, **options)
      @strict_mode = strict_mode
      @options = options
      if model.class.ancestors.include?(Regent::LLM::Base)
        @model = model.model
        @provider = model
      else
        @model = model
        @provider = instantiate_provider
      end
    end

    attr_reader :model, :options

    def invoke(messages, **args)
      retries = 0

      messages = [{ role: "user", content: messages }] if messages.is_a?(String)

      provider.invoke(messages, **args)

    rescue StandardError => error
      if error.respond_to?(:retryable?) && error.retryable? && retries < DEFAULT_RETRY_COUNT
        sleep(exponential_backoff(retries))
        retry
      end
      handle_error(error)
    end

    private

    attr_reader :provider, :strict_mode

    def instantiate_provider
      provider_class = find_provider_class
      raise ProviderNotFoundError, "Provider for #{model} is not found" if provider_class.nil?

      create_provider(provider_class)
    end

    def find_provider_class
      PROVIDER_PATTERNS.find { |key, pattern| model.match?(pattern) }&.first
    end

    def create_provider(provider_class)
      Regent::LLM.const_get(provider_class).new(**options.merge(model: model))
    end

    def handle_error(error)
      message = provider.parse_error(error) || error.message
      raise ApiError, message if strict_mode
      Result.new(model: model, content: message, input_tokens: nil, output_tokens: nil)
    end

    def exponential_backoff(retry_count)
      # Exponential backoff with jitter: 2^n * 100ms + random jitter
      (2**retry_count * 0.1) + rand(0.1)
    end
  end
end
