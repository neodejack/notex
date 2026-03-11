defmodule Notex.Chord.Transform do
  @moduledoc false

  alias Notex.Chord

  def sus2(%Chord{} = chord) do
    chord
    |> Chord.drop_intervals(:drop_three, :three)
    |> Chord.put_intervals(:add_two, :two)
  end

  def sus4(%Chord{} = chord) do
    chord
    |> Chord.drop_intervals(:drop_three, :three)
    |> Chord.put_intervals(:add_four, :four)
  end

  def power(%Chord{} = chord) do
    chord
    |> Chord.drop_intervals(:drop_three, :three)
    |> Chord.drop_intervals(:drop_flat_three, :flat_three)
  end

  def add9(%Chord{} = chord) do
    Chord.put_intervals(chord, :add_ninth, :two, [1])
  end

  def add4(%Chord{} = chord) do
    Chord.put_intervals(chord, :add_fourth, :four)
  end

  def add11(%Chord{} = chord) do
    Chord.put_intervals(chord, :add_eleventh, :four, [1])
  end

  def add13(%Chord{} = chord) do
    Chord.put_intervals(chord, :add_thirteenth, :six, [1])
  end
end
