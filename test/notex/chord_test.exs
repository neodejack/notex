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

    test "raises FunctionClauseError when voicing is not a list" do
      assert_raise FunctionClauseError, fn ->
        put_intervals(new(), :one, 0)
      end
    end
  end
end
