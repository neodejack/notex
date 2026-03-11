defmodule Notex.Chord.Builtin do
  @moduledoc false

  alias Notex.Chord

  def major do
    Chord.put_intervals(Chord.base(), :add_major_triad, [:one, :three, :five])
  end

  def minor do
    Chord.put_intervals(Chord.base(), :add_minor_triad, [:one, :flat_three, :five])
  end

  def diminished do
    minor()
    |> Chord.drop_intervals(:drop_five, :five)
    |> Chord.put_intervals(:add_flat_five, :flat_five)
  end

  def augmented do
    major()
    |> Chord.drop_intervals(:drop_five, :five)
    |> Chord.put_intervals(:add_sharp_five, :sharp_five)
  end

  def major7 do
    Chord.put_intervals(major(), :add_seventh, :seven)
  end

  def minor7 do
    Chord.put_intervals(minor(), :add_seventh, :flat_seven)
  end

  def dominant7 do
    Chord.put_intervals(major(), :add_seventh, :flat_seven)
  end

  def diminished7 do
    Chord.put_intervals(diminished(), :add_seventh, :six)
  end

  def half_diminished7 do
    Chord.put_intervals(diminished(), :add_seventh, :flat_seven)
  end

  def minor_major7 do
    Chord.put_intervals(minor(), :add_seventh, :seven)
  end

  def augmented7 do
    Chord.put_intervals(augmented(), :add_seventh, :flat_seven)
  end

  def major6 do
    Chord.put_intervals(major(), :add_sixth, :six)
  end

  def minor6 do
    Chord.put_intervals(minor(), :add_sixth, :six)
  end
end
