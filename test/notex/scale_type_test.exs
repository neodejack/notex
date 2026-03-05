defmodule Notex.ScaleTypeTest do
  use ExUnit.Case, async: true

  alias Notex.ScaleType

  doctest ScaleType

  defmodule MinorPentatonic do
    @moduledoc false
    @behaviour ScaleType

    def name, do: "pentatonic"
    def intervals, do: [:one, :flat_three, :four, :five, :flat_seven]
  end

  describe "intervals/1" do
    test "returns interval name strings for a custom scale type" do
      assert ScaleType.intervals(MinorPentatonic) == ["1", "b3", "4", "5", "b7"]
    end
  end

  describe "interval_semitones/1" do
    test "returns semitone intervals for a custom scale type" do
      assert ScaleType.interval_semitones(MinorPentatonic) == [0, 3, 5, 7, 10]
    end
  end
end
