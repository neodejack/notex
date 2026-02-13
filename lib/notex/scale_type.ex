defmodule Notex.ScaleType do
  @moduledoc false
  @callback name() :: String.t()
  @callback relative_notes() :: [atom()]

  # TODO: see if there is a way to emit warning if user custom_scale_type.relative_notes() not in Constant.relative_notes() |> Map.keys()
end
