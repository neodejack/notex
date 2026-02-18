defmodule Notex.ScaleType.Major do
  @moduledoc """
  The major scale pattern

  Defines the interval pattern: 1 2 3 4 5 6 7 (whole-whole-half-whole-whole-whole-half).
  """
  @behaviour Notex.ScaleType

  def name, do: "major"
  def relative_notes, do: [:one, :two, :three, :four, :five, :six, :seven]
end

defmodule Notex.ScaleType.Minor do
  @moduledoc """
  The natural minor scale type (Aeolian mode).

  Defines the interval pattern: 1 2 b3 4 5 b6 b7 (whole-half-whole-whole-half-whole-whole).
  """
  @behaviour Notex.ScaleType

  def name, do: "minor"
  def relative_notes, do: [:one, :two, :flat_three, :four, :five, :flat_six, :flat_seven]
end
