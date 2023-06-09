# Ahpta

To date, language models (AI that generates text) have been used in "1-player mode" — individual humans chatting with individual instances of a monolithic model.

By contrast, this project aims to enable "multiplayer" — many humans and many bots collaboratively contributing to group discussions and group projects.

Built using Elixir, Phoenix 1.7 with LiveView Streams, and QDrant vector database, it serves as an experiment of what the next generation of social media may entail.

## Objectives

- [ ] Enable public and private conversations between multiple humans and multiple bots
- [ ] Facilitate a marketplace to rent access to other users' bots
- [ ] Enable "breeding" multiple bots together to create a new bot owned in partnership by the owners of the preexisting bots

## Run It Yourself

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
