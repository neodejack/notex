defmodule Notex.ScaleType do
  @moduledoc false
  alias Notex.Constant

  @callback name() :: String.t()
  @callback relative_notes() :: [atom()]

  # TODO: see if there is a way to emit warning if user custom_scale_type.relative_notes() not in Constant.relative_notes() |> Map.keys()

  @spec relative_notes(module()) :: [binary()]
  def relative_notes(scale_type) when is_atom(scale_type) do
    for r <- scale_type.relative_notes() do
      Map.fetch!(Constant.relative_names(), r)
    end
  end

  @spec relative_semitones(module()) :: [integer()]
  def relative_semitones(scale_type) when is_atom(scale_type) do
    for r <- scale_type.relative_notes() do
      Map.fetch!(Constant.relative_semitones(), r)
    end
  end
end
