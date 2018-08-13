# Copyright (C) 2018 Recogizer Group GmbH - All Rights Reserved
# Unauthorized copying of this file, via any medium is strictly prohibited
# Proprietary and confidential
# Created on 2018-08-13 10:29:11.

defmodule RestarterEx.Backoff do
  # in ms
  @one_second 1000
  @one_hour 3_600_000

  # allowed strategies: :constant, :double, :linear
  defstruct min: @one_second, max: @one_hour, strategy: :constant

  def next(current, %__MODULE__{strategy: :constant}) do
    current
  end

  def next(current, %__MODULE__{strategy: :linear, min: min, max: max}) do
    min(current + min, max)
  end

  def next(current, %__MODULE__{strategy: :double, max: max}) do
    min(current * 2, max)
  end
end
