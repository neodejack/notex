defmodule Notex.KeyTest do
  use ExUnit.Case, async: true

  alias Notex.Key
  alias Notex.Note

  describe "major/1" do
    test "C major" do
      assert ["C4", "D4", "E4", "F4", "G4", "A4", "B4"] =
               %Note{
                 note_name: "C",
                 octave: 4
               }
               |> Key.major()
               |> Enum.map(&to_string/1)
    end

    test "D major" do
      assert ["D4", "E4", "F#4", "G4", "A4", "B4", "C#5"] =
               %Note{
                 note_name: "D",
                 octave: 4
               }
               |> Key.major()
               |> Enum.map(&to_string/1)
    end

    test "E major" do
      assert ["E4", "F#4", "G#4", "A4", "B4", "C#5", "D#5"] =
               %Note{
                 note_name: "E",
                 octave: 4
               }
               |> Key.major()
               |> Enum.map(&to_string/1)
    end

    test "F major" do
      assert ["F4", "G4", "A4", "A#4", "C5", "D5", "E5"] =
               %Note{
                 note_name: "F",
                 octave: 4
               }
               |> Key.major()
               |> Enum.map(&to_string/1)
    end

    test "G major" do
      assert ["G4", "A4", "B4", "C5", "D5", "E5", "F#5"] =
               %Note{
                 note_name: "G",
                 octave: 4
               }
               |> Key.major()
               |> Enum.map(&to_string/1)
    end

    test "A major" do
      assert ["A4", "B4", "C#5", "D5", "E5", "F#5", "G#5"] =
               %Note{
                 note_name: "A",
                 octave: 4
               }
               |> Key.major()
               |> Enum.map(&to_string/1)
    end

    test "B major" do
      assert ["B4", "C#5", "D#5", "E5", "F#5", "G#5", "A#5"] =
               %Note{
                 note_name: "B",
                 octave: 4
               }
               |> Key.major()
               |> Enum.map(&to_string/1)
    end

    test "Db major" do
      assert ["C#4", "D#4", "F4", "F#4", "G#4", "A#4", "C5"] =
               %Note{
                 note_name: "Db",
                 octave: 4
               }
               |> Key.major()
               |> Enum.map(&to_string/1)
    end

    test "Eb major" do
      assert ["D#4", "F4", "G4", "G#4", "A#4", "C5", "D5"] =
               %Note{
                 note_name: "Eb",
                 octave: 4
               }
               |> Key.major()
               |> Enum.map(&to_string/1)
    end

    test "Gb major" do
      assert ["F#4", "G#4", "A#4", "B4", "C#5", "D#5", "F5"] =
               %Note{
                 note_name: "Gb",
                 octave: 4
               }
               |> Key.major()
               |> Enum.map(&to_string/1)
    end

    test "Ab major" do
      assert ["G#4", "A#4", "C5", "C#5", "D#5", "F5", "G5"] =
               %Note{
                 note_name: "Ab",
                 octave: 4
               }
               |> Key.major()
               |> Enum.map(&to_string/1)
    end

    test "Bb major" do
      assert ["A#4", "C5", "D5", "D#5", "F5", "G5", "A5"] =
               %Note{
                 note_name: "Bb",
                 octave: 4
               }
               |> Key.major()
               |> Enum.map(&to_string/1)
    end
  end
end
