defmodule RestarterEx do
  alias RestarterEx.{Backoff, BackoffState}
  require Logger
  use GenServer

  @defaults [
    restart: :permanent,
    shutdown: 5000,
    type: :worker,
    backoff: %Backoff{},
    backoff_state: %BackoffState{}
  ]

  def start(params, opts \\ []) do
    GenServer.start(__MODULE__, params, opts)
  end

  def start_link(params, opts \\ []) do
    GenServer.start_link(__MODULE__, params, opts)
  end

  def init(params) do
    Process.flag(:trap_exit, true)

    state = Keyword.merge(@defaults, params)
    child_spec = Keyword.get(state, :child_spec)

    Logger.debug("Start child with spec: #{}")
    start_child({_child_module, _start_func, _opts} = child_spec)

    {:ok, state}
  end

  def handle_info({:EXIT, pid, reason}, state) do
    Logger.error(
      "RestarterEx receiced exit message with reason #{reason}. " <>
        "Child pid: #{inspect(pid)}."
    )

    restart_config = Keyword.get(state, :restart)
    {child_module, start_call, opts} = Keyword.get(state, :child_spec)
    id = Keyword.get(state, :id, child_module)

    backoff = Keyword.get(state, :backoff)
    backoff_state = Keyword.get(state, :backoff_state)

    handle_child_down(
      reason,
      {child_module, start_call, opts},
      restart_config,
      backoff_state
    )

    new_state = if BackoffState.reset_state?(backoff_state) do
      Keyword.put(
        state,
        :backoff_state,
        BackoffState.reset_state(backoff_state)
      )
    else
      Keyword.put(
        state,
        :backoff_state,
        BackoffState.next(backoff_state, backoff)
      )
    end

    {:noreply, new_state}
  end

  def handle_info({:start_child, config}, state) do
    start_child(config)
    {:noreply, state}
  end

  defp handle_child_down(_, start_config, :permanent, backoff_state) do
    trigger_start_child(start_config, backoff_state)
  end

  defp handle_child_down(_, _, :temporary, _) do
    :ok
  end

  defp handle_child_down(reason, _, :transient, _)
       when reason == :normal or reason == :shutdown do
    :ok
  end

  defp handle_child_down(_, start_config, :transient, backoff_state) do
    trigger_start_child(start_config, backoff_state)
  end

  defp start_child({child_module, function_call, opts}) do
    case apply(child_module, function_call, opts) do
      {:ok, pid} ->
        Process.link(pid)

        Logger.debug(
          "Started child with config " <>
            "#{inspect({child_module, function_call, opts})}; " <>
            "Pid: #{inspect(pid)}"
        )

      {:error, {:already_started, pid}} ->
        Process.link(pid)

        Logger.warn(
          "Tried to start a process which was already alive. " <>
            "Pid: #{inspect(pid)}. " <>
            "Config: #{inspect({child_module, function_call, opts})}."
        )

      _ ->
        send(self(), {:EXIT, nil, :start_failed})
    end
  end

  defp trigger_start_child(config, %{duration: duration} = %BackoffState{}) do
    Process.send_after(self(), {:start_child, config}, duration)
  end
end
