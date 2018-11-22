defmodule RestarterEx.BackoffStateSpec do
  require Logger
  use ExUnit.Case, async: true

  alias RestarterEx.{Backoff, BackoffState}

  describe ".reset_state?" do
    test "returns false when last_time was just short before" do
      backoff_state = %BackoffState{
        duration: 1000,
        last_time: NaiveDateTime.utc_now()
      }

      refute BackoffState.reset_state?(backoff_state)
    end

    test "returns true when last_time was some time before" do
      backoff_state = %BackoffState{
        duration: 1000,
        last_time: NaiveDateTime.utc_now() |> NaiveDateTime.add(-120_000)
      }

      assert BackoffState.reset_state?(backoff_state)
    end
  end

  describe ".reset_state" do
    test "returns a BackoffState with the initial values" do
      backoff = %Backoff{min: 42}

      before_time = NaiveDateTime.utc_now()
      backoff_state = BackoffState.reset_state(backoff)
      after_time = NaiveDateTime.utc_now()

      assert backoff_state.duration == 42
      assert NaiveDateTime.compare(before_time, backoff_state.last_time) != :gt
      assert NaiveDateTime.compare(backoff_state.last_time, after_time) != :gt
    end
  end

  describe ".next" do
    @backoff %Backoff{
      min: 1000,
      max: 6000,
      step_size: 1500
    }
    @backoff_state %BackoffState{
      duration: 2500,
      last_time: NaiveDateTime.utc_now()
    }

    test "updates the state to the next setting for :constant backoffs" do
      backoff = Map.put(@backoff, :strategy, :constant)

      before_time = NaiveDateTime.utc_now()
      new_state = BackoffState.next(@backoff_state, backoff)
      after_time = NaiveDateTime.utc_now()

      assert new_state.duration == @backoff_state.duration
      assert NaiveDateTime.compare(before_time, new_state.last_time) != :gt
      assert NaiveDateTime.compare(new_state.last_time, after_time) != :gt
    end

    test "updates the state to the next setting for :linear backoffs" do
      backoff = Map.put(@backoff, :strategy, :linear)

      before_time = NaiveDateTime.utc_now()
      new_state = BackoffState.next(@backoff_state, backoff)
      after_time = NaiveDateTime.utc_now()

      assert new_state.duration == 4000
      assert NaiveDateTime.compare(before_time, new_state.last_time) != :gt
      assert NaiveDateTime.compare(new_state.last_time, after_time) != :gt
    end

    test "respects the maximum duration for :linear backoffs" do
      backoff = Map.merge(@backoff, %{strategy: :linear, max: 2000})

      before_time = NaiveDateTime.utc_now()
      new_state = BackoffState.next(@backoff_state, backoff)
      after_time = NaiveDateTime.utc_now()

      assert new_state.duration == 2000
      assert NaiveDateTime.compare(before_time, new_state.last_time) != :gt
      assert NaiveDateTime.compare(new_state.last_time, after_time) != :gt
    end

    test "updates the state to the next setting for :double backoffs" do
      backoff = Map.put(@backoff, :strategy, :double)

      before_time = NaiveDateTime.utc_now()
      new_state = BackoffState.next(@backoff_state, backoff)
      after_time = NaiveDateTime.utc_now()

      assert new_state.duration == 5000
      assert NaiveDateTime.compare(before_time, new_state.last_time) != :gt
      assert NaiveDateTime.compare(new_state.last_time, after_time) != :gt
    end

    test "respects the maximum duration for :double backoffs" do
      backoff = Map.merge(@backoff, %{strategy: :double, max: 2000})

      before_time = NaiveDateTime.utc_now()
      new_state = BackoffState.next(@backoff_state, backoff)
      after_time = NaiveDateTime.utc_now()

      assert new_state.duration == 2000
      assert NaiveDateTime.compare(before_time, new_state.last_time) != :gt
      assert NaiveDateTime.compare(new_state.last_time, after_time) != :gt
    end
  end
end
