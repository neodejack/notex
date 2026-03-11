defmodule Notex.Chord.Builtin do
  @moduledoc false

  alias Notex.Chord

  @spec major() :: Chord.t()
  def major do
    Chord.put_intervals(Chord.base(), :add_triad, [:one, :three, :five])
  end

  @spec minor() :: Chord.t()
  def minor do
    Chord.put_intervals(Chord.base(), :add_triad, [:one, :flat_three, :five])
  end
end
