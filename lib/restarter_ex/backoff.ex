# Copyright (C) 2018 Recogizer Group GmbH - All Rights Reserved
# Unauthorized copying of this file, via any medium is strictly prohibited
# Proprietary and confidential
# Created on 2018-08-13 10:29:11.

defmodule RestarterEx.Backoff do
  alias RestarterEx.BackoffState
  # in ms
  @one_second 1000
  @one_hour 3_600_000

  # allowed strategies: :constant, :double, :linear
  defstruct min: @one_second,
            max: @one_hour,
            step_size: @one_second,
            strategy: :constant
end
