defmodule Notex.ScaleType.Major do
  @moduledoc false
  @behaviour Notex.ScaleType

  def name, do: "major"
  def relative_notes, do: [:one, :two, :three, :four, :five, :six, :seven]
end

defmodule Notex.ScaleType.Minor do
  @moduledoc false
  @behaviour Notex.ScaleType

  def name, do: "minor"
  def relative_notes, do: [:one, :two, :flat_three, :four, :five, :flat_six, :seven]
end
