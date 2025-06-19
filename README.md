![regent_light](https://github.com/user-attachments/assets/62564dac-b8d7-4dc0-9b63-64c6841b5872)

<div align="center">

# Regent

[![Gem Version](https://badge.fury.io/rb/regent.svg)](https://badge.fury.io/rb/regent)
[![Build](https://github.com/alchaplinsky/regent/actions/workflows/main.yml/badge.svg)](https://github.com/alchaplinsky/regent/actions/workflows/main.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

</div>

**Regent** is a small and elegant Ruby framework for building AI agents that can think, reason, and take actions through tools. It provides a clean, intuitive interface for creating agents that can solve complex problems by breaking them down into logical steps.

> [!NOTE]
> Regent is currently an experiment intended to explore patterns for building easily traceable and debuggable AI agents of different architectures. It is not yet intended to be used in production and is currently in development.
> 
> Read more about Regent in a Medium article: [Building AI Agent from scratch with Ruby](https://medium.com/towards-artificial-intelligence/building-ai-agent-from-scratch-with-ruby-c6260dad45b7)

#### 📢 Check out TypeScript version https://github.com/alchaplinsky/regent-ts

## Key Features

- **ReAct Pattern Implementation**: Agents follow the Reasoning-Action pattern, making decisions through a clear thought process before taking actions
- **Multi-LLM Support**: Seamlessly works with:
  - OpenAI (GPT models)
  - Anthropic (Claude models)
  - Google (Gemini models)
- **Extensible Tool System**: Create custom tools that agents can use to interact with external services, APIs, or perform specific tasks
- **Built-in Tracing**: Every agent interaction is traced and can be replayed, making debugging and monitoring straightforward
- **Clean Ruby Interface**: Designed to feel natural to Ruby developers while maintaining powerful capabilities

## Showcase

A basic Regnt Agent extended with a `price_tool` that allows for retrieving cryptocurrency prices from coingecko.com.

![Screen_gif](https://github.com/user-attachments/assets/63c8c923-0c1e-48db-99f6-33758411623f)

## Quick Start

```bash
gem install regent
```

or add regent to the Gemfile:

```ruby
gem 'regent'
```

and run

```bash
bundle install
```

## Usage

### Quick Example

Create your first weather agent:

```ruby
# Define agent class
class WeatherAgent < Regent::Agent
  tool(:weather_tool, "Get current weather for a location")

  def weather_tool(location)
    "Currently 72°F and sunny in #{location}"
  end
end

# Instantiate an agent
agent = WeatherAgent.new("You are a helpful weather assistant", model: "gpt-4o")

# Execute a query
agent.run("What's the weather like in Tokyo?") # => "It is currently 72°F and sunny in Tokyo."
```

### LLMs
Regent provides an interface for invoking an LLM through an instance of `Regent::LLM` class. Even though Agent initializer allows you to pass a modal name as a string, sometimes it is useful to create a model instance if you want to tune model params before passing it to the agent. Or if you need to invoke a model directly without passing it to an Agent you can do that by creating an instance of LLM class:

```ruby
model = Regent::LLM.new("gemini-1.5-flash")
# or with options
model = Regent::LLM.new("gemini-1.5-flash", temperature: 0.5) # supports options that are supported by the model
```

#### API keys
By default, **Regent** will try to fetch API keys for corresponding models from environment variables. Make sure that the following ENV variables are set depending on your model choice:

| Model series | ENV variable name   |
|--------------|---------------------|
| `gpt-`       | `OPENAI_API_KEY`    |
| `gemini-`    | `GEMINI_API_KEY`    |
| `claude-`    | `ANTHROPIC_API_KEY` |

But you can also pass an `api_key` option to the` Regent::LLM` constructor should you need to override this behavior:

```ruby
model = Regent::LLM.new("gemini-1.5-flash", api_key: "AIza...")
```

> [!NOTE]
> Currently **Regent** supports only `gpt-`, `gemini-` and `claude-` models series and local **ollama** models. But you can build, your custom model classes that conform to the Regent's interface and pass those instances to the Agent.

> [!NOTE]
> For Claude, Regent uses https://github.com/alexrudall/ruby-anthropic. It will try and load a gem with name `ruby-anthropic`, and fall back to a gem named `anthropic`.

#### Calling LLM
Once your model is instantiated you can call the `invoke` method:

```ruby
model.invoke("Hello!") 
```

Alternatively, you can pass message history to the `invoke` method. Messages need to follow OpenAI's message format (eg. `{role: "user", content: "..."}`)

```ruby
model.invoke([
  {role: "system", content: "You are a helpful assistant"},
  {role: "user", content: "Hello!"}
])
```

This method returns an instance of the `Regent::LLM::Result` class, giving access to the content or error and token usage stats.

```ruby
result = model.invoke("Hello!")

result.content # => Hello there! How can I help you today?
result.input_tokens # => 2
result.output_tokens # => 11
result.error # => nil
```

### Tools

There are multiple ways how you can give agents tools for performing actions and retrieving additional information. First of all you can define a **function tool** directly on the agent class:

```ruby
class MyAgent < Regent::Agent
  # define the tool by giving a unique name and description
  tool :search_web, "Search for information on the web" 

  def search_web(query)
    # Implement tool logic within the method with the same name
  end
end
```

For more complex tools we can define a dedicated class with a `call` method that will get called. And then pass an instance of this tool to an agent:

```ruby
class SearchTool < Regent::Tool
  def call(query)
    # Implement tool logic
  end
end

agent = Regent::Agent.new("Find information and answer any question", {
  model: "gpt-4o",
  tools: [SearchTool.new]
})

```

### Agent

**Agent** class is the core of the library. To crate an agent, you can use `Regent::Agent` class directly if you don't need to add any business logic. Or you can create your own class inheriting from `Regent::Agent`. To instantiate an agent you need to pass a **purpose** of an agent and a model it should use.

```ruby
agent = Regent::Agent.new("You are a helpful assistant", model: "gpt-4o-mini")
```

Additionally, you can pass a list of Tools to extend the agent's capabilities. Those should be instances of classes that inherit from `Regent::Tool` class:

```ruby
class SearchTool < Regent::Tool
  def call
    # make a call to search API
  end
end

class CalculatorTool < Regent::Tool
  def call
    # perform calculations
  end
end

tools = [SearchTool.new, CalculatorTool.new]

agent = Regent::Agent.new("You are a helpful assistant", model: "gpt-4o-mini", tools: tools)
```

Each agent run creates a **session** that contains every operation that is performed by the agent while working on a task. Sessions can be replayed and drilled down into while debugging.
```ruby
agent.sessions # => Returns all sessions performed by the agent
agent.session # => Returns last session performed by the agent
agent.session.result # => Returns result of latest agent run
```

While running agent logs all session spans (all operations) to the console with all sorts of useful information, that helps to understand what the agent was doing and why it took a certain path.
```ruby
weather_agent.run("What is the weather in San Francisco?")
```

Outputs:
```console
[✔] [INPUT][0.0s]: What is the weather in San Francisco?
 ├──[✔] [LLM ❯ gpt-4o-mini][242 → 30 tokens][0.02s]: What is the weather in San Francisco?
 ├──[✔] [TOOL ❯ get_weather][0.0s]: ["San Francisco"] → The weather in San Francisco is 70 degrees and sunny.
 ├──[✔] [LLM ❯ gpt-4o-mini][294 → 26 tokens][0.01s]: Observation: The weather in San Francisco is 70 degrees and sunny.
[✔] [ANSWER ❯ success][0.03s]: It is 70 degrees and sunny in San Francisco.
```

### Engine
By default, Regent uses ReAct agent architecture. You can see the [details of its implementation](https://github.com/alchaplinsky/regent/blob/main/lib/regent/engine/react.rb). However, Agent constructor accepts an `engine` option that allows you to swap agent engine when instantiating an Agent. This way you can implement your own agent architecture that can be plugged in and user within Regent framework.

```ruby
agent = CustomAgent.new("You are a self-correcting assistant", model: "gpt-4o", engine: CustomEngine)
```

In order to implement your own engine you need to define a class that inherits from `Regent::Engine::Base` class and implements `reason` method:

```ruby
class CustomEngine < Regent::Engine::Base
  def reason(task)
    # Your implementation of an Agent lifecycle
  end
end
```

Note that Base class already handles `max_iteration` check, so you won't end up in an infinite loop. Also, it allows you to use `llm_call_response` and `tool_call_response` methods for agent reasoning as well as `success_answer` and `error_answer` for the final result.

For any other operation that happens in your agent architecture that you want to track separately call it within the `session.exec` block. See examples in `Regent::Engine::Base` class.


---
## Why Regent?

- **Transparent Decision Making**: Watch your agent's thought process as it reasons through problems
- **Flexible Architecture**: Easy to extend with custom tools and adapt to different use cases
- **Ruby-First Design**: Takes advantage of Ruby's elegant syntax and conventions
- **Transparent Execution**: Built with tracing, error handling, and clean abstractions


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/alchaplinsky/regent. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/alchaplinsky/regent/blob/main/CODE_OF_CONDUCT.md).

## Code of Conduct

Everyone interacting in the Regent project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/alchaplinsky/regent/blob/main/CODE_OF_CONDUCT.md).
