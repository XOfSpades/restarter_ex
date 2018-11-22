defmodule RestarterExTest do
  use ExUnit.Case

  alias RestarterEx.Support.DyingGenServer

  doctest RestarterEx

  test "restarts a GenServer" do
    backoff = %RestarterEx.Backoff{strategy: :linear}

    child_spec = %{
      start: {DyingGenServer, :start_link, [[]]},
      id: DyingGenServer.name()
    }

    {:ok, restarter_pid} =
      RestarterEx.start(
        [
          child_spec: {DyingGenServer, :start_link, [[]]},
          child_id: DyingGenServer.name(),
          backoff: backoff
        ],
        name: :test_restarter
      )

    :timer.sleep(1000)

    server_pid = Process.whereis(DyingGenServer.name())

    assert is_pid(server_pid)

    GenServer.stop(DyingGenServer.name(), :error, 100)

    :timer.sleep(4000)

    new_server_pid = Process.whereis(DyingGenServer.name())

    assert Process.alive?(restarter_pid)

    assert is_pid(new_server_pid)
    assert server_pid != new_server_pid

    GenServer.stop(DyingGenServer.name(), :error, 100)

    :timer.sleep(4000)

    new_server_pid = Process.whereis(DyingGenServer.name())

    assert Process.alive?(restarter_pid)

    assert is_pid(new_server_pid)
    assert server_pid != new_server_pid
  end
end
