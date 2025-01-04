# frozen_string_literal: true

module Regent
  class LLM
    class Anthropic < Base
      MAX_TOKENS = 1000
      ENV_KEY = "ANTHROPIC_API_KEY"

      depends_on "anthropic"

      def invoke(messages, **args)
        response = client.messages(parameters: {
          messages: format_messages(messages),
          system: system_instruction(messages),
          model: model,
          temperature: args[:temperature] || 0.0,
          stop_sequences: args[:stop] || [],
          max_tokens: MAX_TOKENS
        })

        result(
          model: model,
          content: response.dig("content", 0, "text"),
          input_tokens: response.dig("usage", "input_tokens"),
          output_tokens: response.dig("usage", "output_tokens")
        )
      end

      private

      def client
        @client ||= ::Anthropic::Client.new(access_token: api_key)
      end

      def system_instruction(messages)
        messages.find { |message| message[:role].to_s == "system" }&.dig(:content)
      end

      def format_messages(messages)
        messages.reject { |message| message[:role].to_s == "system" }
      end
    end
  end
end
