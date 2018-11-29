# RestarterEx

## Basic usage

Initially you should befine a backoff. If you don't a constant backoff of one seconf is assumed:

```
backoff = RestarterEx.Backoff{
  min: 1000, # in ms
  max: 3600000, # in ms
  step_size: 2000, # in ms; Only needed when strategy is linear
  strategy: :linear # or :constant or :double'
}
```

Add RestarerEx to your supervision tree which will start your GenServer underneath:

```
Supervisor.Spec.worker(
        RestarterEx,
        [
          [
            child_spec:
              {
                MyModule.MyGenServer,
                :start_link,
                my_args
              },
            backoff: backoff
          ]
        ],
        id: :restarter_id
      )
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `restarter_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:restarter_ex, "~> 0.1.0"}
  ]
end
```
