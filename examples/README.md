# GomAgents example application

## Running the example

 * cd into the examples/application directory
 * setup your ruby environment (e.g. .ruby-version and .ruby-gemset)
 * run bundler install
 * run agents

## Application Structure

GomAgents promotes a highly modular structure involving several repositories: your application repository and your agent repositories:

 * All your business logic should be implemented in the agents
 * Agents should be packaged as gems. Several agents can be packaged together in one gem if they are tightly coupled and meant to be used together.
 * Each gem should have its own project/repository, including its own Gemfile. This is also where you can specify dependencies between agents.
 * Each agent should usually consist of one or more celluloid actors.
 * The application project contains nearly no code, it just assembles the agents which be be started by Gom::Agents::App

By spitting up the agents into different repositories/gems, it becomes possible to segregate reusable, general-use agents from application domain specific agents.
