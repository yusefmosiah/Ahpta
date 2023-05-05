defmodule Ahpta.BotsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ahpta.Bots` context.
  """

  @doc """
  Generate a bot.
  """
  def bot_fixture(attrs \\ %{}) do
    {:ok, bot} =
      attrs
      |> Enum.into(%{
        is_available_for_rent: true,
        name: "some name",
        system_message: "some system message"
      })
      |> Ahpta.Bots.create_bot()

    bot
  end
end
