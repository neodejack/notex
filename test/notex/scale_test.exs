defmodule Notex.ScaleTest do
  use ExUnit.Case, async: true

  import Notex.Note

  alias Notex.Scale
  alias Notex.ScaleType

  doctest Scale

  describe "notes/2" do
    test "C major" do
      assert ["C4", "D4", "E4", "F4", "G4", "A4", "B4"] = scale_notes_string(~n[C4], ScaleType.Major)
    end

    test "G major" do
      assert ["G4", "A4", "B4", "C5", "D5", "E5", "F#5"] = scale_notes_string(~n[G4], ScaleType.Major)
    end

    test "B# major (enharmonic to C)" do
      assert ["C4", "D4", "E4", "F4", "G4", "A4", "B4"] = scale_notes_string(~n[B#3], ScaleType.Major)
    end

    test "tonic above C9 returns error" do
      assert {:error, reason} = Scale.notes(~n[C#9], ScaleType.Major)
      assert reason =~ "not valid"
    end

    test "tonic at C9 succeeds (boundary)" do
      assert {:ok, _notes} = Scale.notes(~n[C9], ScaleType.Major)
    end

    test "tonic at B8 succeeds" do
      assert {:ok, _notes} = Scale.notes(~n[B8], ScaleType.Major)
    end
  end

  describe "atom scale type resolution" do
    test "lowercase atom scale_type" do
      assert ["C4", "D4", "E4", "F4", "G4", "A4", "B4"] = scale_notes_string(~n[C4], :major)
    end

    test "capitalized atom scale_type" do
      assert ["C4", "D4", "E4", "F4", "G4", "A4", "B4"] = scale_notes_string(~n[C4], :Major)
    end

    test "undefined scale type returns error" do
      assert {:error, reason} = Scale.notes(~n[C4], :nonexistent)
      assert reason =~ "not found"
    end
  end

  describe "custom scale type notes/2" do
    defmodule MinorPentatonic do
      @moduledoc false
      @behaviour ScaleType

      def name, do: "minor pentatonic"
      def relative_notes, do: [:one, :flat_three, :four, :five, :flat_seven]
    end

    test "full module name" do
      assert ["C4", "D#4", "F4", "G4", "A#4"] = scale_notes_string(~n[C4], MinorPentatonic)
    end
  end

  defp scale_notes_string(tonic, scale_type) do
    {:ok, notes} = Scale.notes(tonic, scale_type)
    Enum.map(notes, &to_string/1)
  end
end
