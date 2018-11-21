defmodule RestarterEx do
  require Logger
  use GenServer

  @defaults %{
    restart: :permanent,
    shutdown: 5000,
    type: :worker,
    backoff: %RestarterEx.Backoff{}
  }

  def restarted(child_spec, id \\ __MODULE__) do
    %{
      id: id,
      restart: :permanent,
      shutdown: 6000,
      start: {
        __MODULE__,
        :start_link,
        [[child_spec: child_spec]]
      },
      type: :worker
    }
  end

  def start(params, opts \\ []) do
    GenServer.start(__MODULE__, params, opts)
  end

  def start_link(params, opts \\ []) do
    GenServer.start_link(__MODULE__, params, opts)
  end

  def init(options) do
    state = Map.merge(@defaults, Keyword.get(options, :child_spec))
    %{start: {child_module, function_call, opts}, id: module_id} = state

    Logger.debug("Start child:")
    start_child({child_module, function_call, opts}, module_id)

    {:ok, state}
  end

  def handle_info({:DOWN, _reference, :process, pid, reason}, state) do
    Logger.warn(
      "RestarterEx receiced down message with reason #{reason}. " <>
        "Child pid: #{inspect(pid)}."
    )

    restart_config = Map.get(state, :restart)
    {child_module, start_call, opts} = Map.get(state, :start)
    id = Map.get(state, :id, child_module)

    handle_child_down(
      reason,
      {child_module, start_call, opts},
      id,
      restart_config
    )

    {:noreply, state}
  end

  defp handle_child_down(_, start_config, id, :permanent) do
    start_child(start_config, id)
  end

  defp handle_child_down(_, _, :temporary) do
    :ok
  end

  defp handle_child_down(reason, _, _, :transient)
      when reason == :normal or reason == :shutdown do
    :ok
  end

  defp handle_child_down(_, start_config, id, :transient) do
    start_child(start_config, id)
  end

  defp start_child({child_module, function_call, opts}, id) do
    Logger.info(
      "Start child #{child_module} with function #{function_call} and " <>
        "options #{inspect(opts)}"
    )

    try do
      case apply(child_module, function_call, opts) do
        {:ok, pid} ->
          Process.unlink(pid)
          IO.puts "\n\nProcess pid: #{inspect pid} is alive? #{Process.alive?(pid)}; new id: #{id}"
          Process.monitor(pid)
          IO.puts("Alive? #{Process.alive?(pid)}")

          :ok

        _ ->
          send(self(), {:DOWN, nil, :process, nil, :start_failed})
      end
    rescue
      err ->
        Logger.error(
          "Exception was raised while starting child " <>
          "process: #{inspect err}. Try to restart."
        )
        send(self(), {:DOWN, nil, :process, nil, :start_failed})
    end
  end
end
