import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :ahpta, Ahpta.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "ahpta_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ahpta, AhptaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "HeFtQ58OczJnqzwr55X7L1XMTbu5uYQvDqmrkbEsTfHd+34LDCiR208mwUawXK+y",
  server: false

# In test we don't send emails.
config :ahpta, Ahpta.Mailer, adapter: Swoosh.Adapters.Test

config :ahpta, :chat_module, Ahpta.OpenAIMock

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
