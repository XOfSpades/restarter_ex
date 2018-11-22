defmodule RestarterEx.BackoffState do
  alias RestarterEx.Backoff

  @one_second 1000

  defstruct last_time: nil,
            duration: @one_second

  def reset_state?(%__MODULE__{last_time: nil}), do: false

  def reset_state?(%__MODULE__{last_time: last_time, duration: duration}) do
    seconds_before = -60_000 - (duration || 0)

    time_border =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(seconds_before, :seconds)

    NaiveDateTime.compare(last_time, time_border) == :lt
  end

  def reset_state(%Backoff{min: min_backoff}) do
    %__MODULE__{
      last_time: NaiveDateTime.utc_now(),
      duration: min_backoff
    }
  end

  def next(state = %__MODULE__{}, %Backoff{strategy: :constant}) do
    Map.put(state, :last_time, NaiveDateTime.utc_now())
  end

  def next(%{duration: duration}, %Backoff{
        strategy: :linear,
        step_size: step_size,
        max: max
      }) do
    %__MODULE__{
      last_time: NaiveDateTime.utc_now(),
      duration: min(duration + step_size, max)
    }
  end

  def next(%{duration: duration}, %Backoff{strategy: :double, max: max}) do
    %__MODULE__{
      last_time: NaiveDateTime.utc_now(),
      duration: min(duration * 2, max)
    }
  end
end
