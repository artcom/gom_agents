# GomAgents example application

## Running the example

 * cd into the examples/application directory
 * setup your ruby environment (e.g. .ruby-version and .ruby-gemset)
 * run bundler install
 * run agents

## Application Structure

GomAgents promotes a highly modular structure involving several repositories: your application repository and your agent repositories:

 * all your business logic should be implemented in the agents
 * agents should be packages as gems. Several agents can be packages together in one gem if they are tightly coupled and meant to be used together
 * each gem should have its own project/repository, including its own Gemfile. This is also where you can specify dependencies between agents.
 * each agent should usually consist of one or more celluloid actors
 * The application project contains nearly no code, it just assembles the agents which be be started by Gom::Agents::App

by spitting up the agents into different repositories/gems, it becomes possible to segregate reusable, general-use agents from application domain specific agents.
