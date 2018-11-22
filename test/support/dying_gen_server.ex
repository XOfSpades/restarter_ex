# Copyright (C) 2018 Recogizer Group GmbH - All Rights Reserved
# Unauthorized copying of this file, via any medium is strictly prohibited
# Proprietary and confidential
# Created on 2018-11-20 14:37:39.

defmodule RestarterEx.Support.DyingGenServer do
  use GenServer
  require Logger

  @timeout 200

  def name, do: __MODULE__

  def start(_, opts \\ [name: __MODULE__]) do
    Logger.info("start DyingGenServer")

    GenServer.start(
      __MODULE__,
      [],
      Keyword.merge([name: __MODULE__], opts)
    )
  end

  def start_link(_, opts \\ [name: __MODULE__]) do
    #    Logger.info("start_link DyingGenServer")
    GenServer.start_link(
      __MODULE__,
      [],
      Keyword.merge([name: __MODULE__], opts)
    )
  end

  def init(state) do
    Logger.info("Init DyingGenServer")
    {:ok, state}
  end

  def handle_info(:die, state) do
    pid = self()
    {:noreply, state}
  end
end
