defmodule RestarterExTest do
  use ExUnit.Case

  alias RestarterEx.Support.DyingGenServer

  doctest RestarterEx

  test "restarts a GenServer" do
    child_spec = %{
      start: {DyingGenServer, :start_link, [[]]},
      id: DyingGenServer.name
    }

    {:ok, pid} =
      RestarterEx.start(
        [child_spec: child_spec],
        name: :test_restarter
      )

    :timer.sleep(1000)

    server_pid = Process.whereis(DyingGenServer.name)

    assert is_pid(server_pid)

    GenServer.stop(DyingGenServer.name, :error, 100)

    :timer.sleep(4000)

    new_server_pid = Process.whereis(DyingGenServer.name)

    assert Process.alive?(pid)

    assert is_pid(new_server_pid)
    assert server_pid != new_server_pid
  end
end
