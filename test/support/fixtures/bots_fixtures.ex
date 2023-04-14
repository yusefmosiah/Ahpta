defmodule Capstone.BotsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Capstone.Bots` context.
  """

  @doc """
  Generate a bot.
  """
  def bot_fixture(attrs \\ %{}) do
    {:ok, bot} =
      attrs
      |> Enum.into(%{
        is_available_for_rent: true,
        name: "some name"
      })
      |> Capstone.Bots.create_bot()

    bot
  end
end
