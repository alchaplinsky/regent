# frozen_string_literal: true

RSpec.describe Regent::LLM do
  let(:strict_mode) { true }
  let(:messages) { [{ role: :user, content: "What is the capital of Japan?" }] }

  subject { Regent::LLM.new(model, strict_mode: strict_mode) }

  context "OpenAI", vcr: true do
    let(:model) { "gpt-4o-mini" }
    let(:cassette) { "LLM/OpenAI/success_response" }

    it "returns a model response" do
      result = subject.invoke(messages)
      expect(result).to be_a(Regent::LLM::Result)
      expect(result.content).to eq("The capital of Japan is Tokyo.")
    end
  end

  context "OpenAICompatible", vcr: true do
    let(:model) { Regent::LLM::OpenAI.new(model: "qwen-qwq-32b", api_key: 'api_key', uri_base: 'https://api.groq.com/openai') }
    let(:cassette) { "LLM/OpenAI/compatible_success_response" }

    it "returns a model response" do
      result = subject.invoke(messages)
      expect(result).to be_a(Regent::LLM::Result)
      expect(result.content).to eq("The capital of Japan is Tokyo.")
    end
  end

  context "Gemini", vcr: true do
    let(:model) { "gemini-1.5-flash" }
    let(:cassette) { "LLM/Google_Gemini/success_response" }

    it "returns a model response" do
      result = subject.invoke(messages)
      expect(result).to be_a(Regent::LLM::Result)
      expect(result.content).to eq("Tokyo")
    end
  end

  context "Anthropic", vcr: true do
    let(:model) { "claude-3-5-sonnet-20240620" }
    let(:cassette) { "LLM/Anthropic/success_response" }

    it "returns a model response" do
      result = subject.invoke(messages)
      expect(result).to be_a(Regent::LLM::Result)
      expect(result.content).to eq("The capital of Japan is Tokyo. Tokyo has been the capital of Japan since 1868, when it replaced Kyoto as the seat of the Emperor and the national government. It is the most populous metropolitan area in the world and serves as Japan's political, economic, and cultural center. Tokyo is known for its unique blend of modern technology and traditional culture, bustling urban areas, and efficient transportation systems.")
    end
  end

  context "Ollama", vcr: true do
    let(:model) { Regent::LLM::Ollama.new(model: "gemma") }
    let(:cassette) { "LLM/Ollama/success_response" }

    it "returns a model response" do
      result = subject.invoke(messages)
      expect(result).to be_a(Regent::LLM::Result)
      expect(result.content).to eq("The capital city of Japan is Tokyo.\n\nIt is the political, economic, and cultural center of Japan and is known for its modern cityscape and traditional culture.")
    end
  end

  context "Unsupported model" do
    let(:model) { "llama-3.1-8b" }

    it "raises an error if the model is not supported" do
      expect { subject }.to raise_error(Regent::LLM::ProviderNotFoundError)
    end
  end

  context "API key not set in environment" do
    let(:model) { "gpt-4o-mini" }

    it "raises an error if the API key is not set" do
      original_api_key = ENV["OPENAI_API_KEY"]
      ENV["OPENAI_API_KEY"] = nil
      expect { subject }.to raise_error(Regent::LLM::APIKeyNotFoundError)
    ensure
      ENV["OPENAI_API_KEY"] = original_api_key
    end
  end

  context "API error", vcr: true do
    context "OpenAI" do
      let(:model) { "gpt-4.1o-mini" }
      let(:cassette) { "LLM/OpenAI/non_existent_model" }

      context "strict mode" do
        it "raises an API error" do
          expect { subject.invoke(messages) }.to raise_error(
            Regent::LLM::ApiError,
            "The model `gpt-4.1o-mini` does not exist or you do not have access to it."
          )
        end
      end

      context "non strict mode" do
        let(:strict_mode) { false }

        it "returns a result with error message" do
          result = subject.invoke(messages)
          expect(result).to be_a(Regent::LLM::Result)
          expect(result.content).to eq("The model `gpt-4.1o-mini` does not exist or you do not have access to it.")
        end
      end
    end

    context "Gemini" do
      let(:model) { "gemini-3.5-flash" }
      let(:cassette) { "LLM/Google_Gemini/non_existent_model" }

      context "strict mode" do
        it "raises an API error" do
          expect { subject.invoke(messages) }.to raise_error(
            Regent::LLM::ApiError,
            "models/gemini-3.5-flash is not found for API version v1, or is not supported for generateContent. Call ListModels to see the list of available models and their supported methods."
          )
        end
      end

      context "non strict mode" do
        let(:strict_mode) { false }

        it "returns a result with error message" do
          result = subject.invoke(messages)
          expect(result).to be_a(Regent::LLM::Result)
          expect(result.content).to eq("models/gemini-3.5-flash is not found for API version v1, or is not supported for generateContent. Call ListModels to see the list of available models and their supported methods.")
        end
      end
    end

    context "Anthropic" do
      let(:model) { "claude-4.1-haiku" }
      let(:cassette) { "LLM/Anthropic/non_existent_model" }

      context "strict mode" do
        it "raises an API error" do
          expect { subject.invoke(messages) }.to raise_error(
            Regent::LLM::ApiError,
            "system: Input should be a valid list"
          )
        end
      end

      context "non strict mode" do
        let(:strict_mode) { false }

        it "returns a result with error message" do
          result = subject.invoke(messages)
          expect(result).to be_a(Regent::LLM::Result)
          expect(result.content).to eq("system: Input should be a valid list")
        end
      end
    end

    context "Ollama" do
      let(:model) { Regent::LLM::Ollama.new(model: "llama3.1")   }
      let(:cassette) { "LLM/Ollama/non_existent_model" }

      it "raises an API error" do
        expect { subject.invoke(messages) }.to raise_error(Regent::LLM::ApiError)
      end

      context "non strict mode" do
        let(:strict_mode) { false }

        it "returns a result with error message" do
          result = subject.invoke(messages)
          expect(result).to be_a(Regent::LLM::Result)
          expect(result.content).to eq("model \"llama3.1\" not found, try pulling it first")
        end
      end
    end
  end

  context "Missing model dependency" do
    let(:model) { "claude-3-5-sonnet-20240620" }

    before do
      allow(Regent::Logger).to receive(:warn_and_exit).and_return(true)
      allow_any_instance_of(Regent::LLM::Anthropic).to receive(:gem).with("anthropic").and_raise(Gem::LoadError)
      allow_any_instance_of(Regent::LLM::Anthropic).to receive(:gem).with("ruby-anthropic").and_raise(Gem::LoadError)
    end

    it "warns and exists if the dependency is not installed" do
      subject

      expect(Regent::Logger).to have_received(:warn_and_exit).with(
         /\n.*In order to use .*claude-3-5-sonnet-20240620.* model you need to install one of: .*ruby-anthropic, anthropic.*. Please add .*gem "ruby-anthropic".* or .*gem "anthropic".* to your Gemfile.*/
      )
    end
  end
end
