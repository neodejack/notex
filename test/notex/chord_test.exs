defmodule Notex.ChordTest do
  use ExUnit.Case, async: true
  use Notex

  import Notex.Chord

  describe "put_intervals/2" do
    test "adds a single interval with default voicing" do
      {:ok, chord} =
        new()
        |> put_intervals(:one)
        |> build()

      assert chord.voicings == [one: [0]]
    end

    test "adds a list of intervals with default voicing" do
      {:ok, chord} =
        new()
        |> put_intervals([:one, :three, :five])
        |> build()

      assert chord.voicings == [five: [0], three: [0], one: [0]]
    end

    test "empty list is a no-op" do
      {:ok, chord} =
        new()
        |> put_intervals([])
        |> build()

      assert chord.voicings == []
    end
  end

  describe "put_intervals/3" do
    test "adds a single interval with custom voicing" do
      {:ok, chord} =
        new()
        |> put_intervals(:one, [-1, 0])
        |> build()

      assert chord.voicings == [one: [-1, 0]]
    end

    test "adds a list of intervals with custom voicing" do
      {:ok, chord} =
        new()
        |> put_intervals([:one, :three, :five], [-1, 0, 1])
        |> build()

      assert chord.voicings == [five: [-1, 0, 1], three: [-1, 0, 1], one: [-1, 0, 1]]
    end

    test "overwrites an existing interval" do
      {:ok, chord} =
        new()
        |> put_intervals(:one, [0])
        |> put_intervals(:one, [-1, 0])
        |> build()

      assert chord.voicings == [one: [-1, 0]]
    end
  end

  describe "update_voicing/3" do
    test "updates an existing interval's voicing via callback" do
      {:ok, chord} =
        new()
        |> put_intervals(:one, [0])
        |> update_voicing(:one, fn _existing -> [-1, 0, 1] end)
        |> build()

      assert chord.voicings == [one: [-1, 0, 1]]
    end

    test "callback receives the current voicing" do
      {:ok, chord} =
        new()
        |> put_intervals(:one, [-1, 0])
        |> update_voicing(:one, fn existing -> existing ++ [1] end)
        |> build()

      assert chord.voicings == [one: [-1, 0, 1]]
    end

    test "returns error when interval does not exist" do
      {:error, msg} =
        new()
        |> update_voicing(:five, fn v -> v end)
        |> build()

      assert msg == "interval :five does not exist in chord voicings"
    end

    test "multiple updates apply in order" do
      {:ok, chord} =
        new()
        |> put_intervals(:one, [0])
        |> update_voicing(:one, fn _ -> [1] end)
        |> update_voicing(:one, fn existing -> [-1 | existing] end)
        |> build()

      assert chord.voicings == [one: [-1, 1]]
    end
  end
end
