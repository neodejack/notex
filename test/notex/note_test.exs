defmodule Notex.NoteTest do
  use ExUnit.Case, async: true

  import Notex.Note

  alias Notex.Note

  describe "parse/1" do
    test "parses simple natural notes" do
      assert {:ok, %Note{note_name: "C", octave: 4}} = parse("C4")
    end

    test "normalizes lowercase input" do
      assert {:ok, %Note{note_name: "G", octave: 2}} = parse("g2")
    end

    test "parses sharp notes" do
      assert {:ok, %Note{note_name: "F#", octave: 9}} = parse("F#9")
    end

    test "parses flat notes by converting them to their enharmonic sharp" do
      assert {:ok, %Note{note_name: "G#", octave: 3}} = parse("Ab3")
    end

    test "parses B# by canonicalizing to C with octave+1" do
      assert {:ok, %Note{note_name: "C", octave: 4}} = parse("B#3")
    end

    test "parses E# by canonicalizing to F" do
      assert {:ok, %Note{note_name: "F", octave: 4}} = parse("E#4")
    end

    test "parses Cb by canonicalizing to B with octave-1" do
      assert {:ok, %Note{note_name: "B", octave: 3}} = parse("Cb4")
    end

    test "parses Fb by canonicalizing to E" do
      assert {:ok, %Note{note_name: "E", octave: 4}} = parse("Fb4")
    end

    test "B#9 is out of range (would be C10)" do
      assert {:error, message} = parse("B#9")
      assert message =~ "Invalid octave"
    end

    test "Cb0 is out of range (would be B-1)" do
      assert {:error, message} = parse("Cb0")
      assert message =~ "Invalid octave"
    end

    test "rejects note names outside the musical alphabet (H1)" do
      assert {:error, message} = parse("H1")
      assert message =~ "Invalid note_name"
    end

    test "rejects malformed accidental notation (T-4)" do
      assert {:error, message} = parse("T-4")
      assert message =~ "Invalid note_name"
    end

    test "rejects invalid lowercase-only note names (ii)" do
      assert {:error, message} = parse("ii")
      assert message =~ "Invalid octave"
    end

    test "requires an octave character (A)" do
      assert {:error, message} = parse("A")
      assert message =~ "Bad note shape"
    end

    test "requires an octave character (Ab)" do
      assert {:error, message} = parse("Ab")
      assert message =~ "Invalid octave"
    end

    test "rejects non-digit octave characters" do
      assert {:error, message} = parse("C#x")
      assert message =~ "Invalid octave"
    end

    test "rejects inputs that are not exactly two or three characters long" do
      assert {:error, message} = parse("C#44")
      assert message =~ "Bad note shape"
    end
  end

  describe "equal?/2" do
    test "G4" do
      note1 = ~n[g4]
      note2 = ~n[G4]

      assert true = equal?(note1, note2)
    end

    test "B#3 equals C4" do
      assert true = equal?(~n[B#3], ~n[C4])
    end

    test "Cb4 equals B3" do
      assert true = equal?(~n[Cb4], ~n[B3])
    end

    test "E#4 equals F4" do
      assert true = equal?(~n[E#4], ~n[F4])
    end

    test "Fb4 equals E4" do
      assert true = equal?(~n[Fb4], ~n[E4])
    end
  end

  describe "transpose!/2 when semitone > 0" do
    test "normal notes" do
      assert ~n[C#4] == transpose!(~n[C4], 1)
      assert ~n[F4] == transpose!(~n[C4], 5)
    end

    test "octave boundary - going up" do
      assert ~n[C5] == transpose!(~n[B4], 1)
      assert ~n[C#5] == transpose!(~n[B4], 2)
      assert ~n[D#6] == transpose!(~n[B5], 4)
      assert ~n[F7] == transpose!(~n[A#6], 7)
    end

    test "transposing sharp notes upward" do
      assert ~n[E4] == transpose!(~n[C#4], 3)
      assert ~n[C#6] == transpose!(~n[F#5], 7)
      assert ~n[G4] == transpose!(~n[G#3], 11)
      assert ~n[F#5] == transpose!(~n[D#4], 15)
    end

    test "transposing natural notes by single semitone" do
      assert ~n[C#4] == transpose!(~n[C4], 1)
      assert ~n[D4] == transpose!(~n[C4], 2)
      assert ~n[F4] == transpose!(~n[E4], 1)
      assert ~n[G4] == transpose!(~n[F4], 2)
    end

    test "high octave transpositions" do
      assert ~n[C9] == transpose!(~n[C8], 12)
      assert ~n[D9] == transpose!(~n[A8], 5)
      assert ~n[B8] == transpose!(~n[G#8], 3)
      assert ~n[F#9] == transpose!(~n[E9], 2)
    end

    test "low octave transpositions upward" do
      assert ~n[C1] == transpose!(~n[C0], 12)
      assert ~n[D1] == transpose!(~n[A0], 5)
      assert ~n[B0] == transpose!(~n[E0], 7)
      assert ~n[F1] == transpose!(~n[C0], 17)
    end

    test "large upward transpositions" do
      assert ~n[C6] == transpose!(~n[C4], 24)
      assert ~n[A7] == transpose!(~n[A3], 48)
      assert ~n[E6] == transpose!(~n[E2], 48)
      assert ~n[G7] == transpose!(~n[C4], 43)
    end

    test "zero transposition" do
      assert ~n[D4] == transpose!(~n[D4], 0)
      assert ~n[F#5] == transpose!(~n[F#5], 0)
      assert ~n[A0] == transpose!(~n[A0], 0)
      assert ~n[B9] == transpose!(~n[B9], 0)
    end

    test "common musical intervals - upward" do
      assert ~n[B4] == transpose!(~n[E4], 7)
      assert ~n[A4] == transpose!(~n[A3], 12)
      assert ~n[F#5] == transpose!(~n[F4], 13)
      assert ~n[G5] == transpose!(~n[C5], 7)
    end

    test "transposing across multiple octaves" do
      assert ~n[A#6] == transpose!(~n[C4], 34)
      assert ~n[C8] == transpose!(~n[F#5], 30)
      assert ~n[G#7] == transpose!(~n[B3], 45)
      assert ~n[F9] == transpose!(~n[G6], 34)
    end

    test "edge cases with B and C note transitions" do
      assert ~n[C6] == transpose!(~n[B5], 1)
      assert ~n[E6] == transpose!(~n[B5], 5)
      assert ~n[C4] == transpose!(~n[B3], 1)
      assert ~n[D5] == transpose!(~n[B4], 3)
    end
  end

  describe "transpose!/2 when semitone < 0" do
    test "normal notes" do
      assert ~n[C4] == transpose!(~n[C#4], -1)
      assert ~n[C4] == transpose!(~n[F4], -5)
    end

    test "octave boundary - going down" do
      assert ~n[B4] == transpose!(~n[C5], -1)
      assert ~n[A#4] == transpose!(~n[C5], -2)
      assert ~n[C4] == transpose!(~n[C#4], -1)
      assert ~n[B3] == transpose!(~n[D4], -3)
    end

    test "transposing sharp notes downward" do
      assert ~n[C#4] == transpose!(~n[F#4], -5)
      assert ~n[C#5] == transpose!(~n[G#5], -7)
      assert ~n[G3] == transpose!(~n[D#4], -8)
      assert ~n[B5] == transpose!(~n[A#6], -11)
    end

    test "transposing natural notes downward" do
      assert ~n[C#4] == transpose!(~n[E4], -3)
      assert ~n[D4] == transpose!(~n[G4], -5)
      assert ~n[D5] == transpose!(~n[A5], -7)
      assert ~n[F5] == transpose!(~n[D6], -9)
    end

    test "high octaves going down" do
      assert ~n[C8] == transpose!(~n[C9], -12)
      assert ~n[A#8] == transpose!(~n[F9], -7)
      assert ~n[F#7] == transpose!(~n[A8], -15)
      assert ~n[C8] == transpose!(~n[G#9], -20)
    end

    test "low octaves going down" do
      assert ~n[C0] == transpose!(~n[C1], -12)
      assert ~n[B0] == transpose!(~n[E1], -5)
      assert ~n[B0] == transpose!(~n[A1], -10)
      assert ~n[A#0] == transpose!(~n[F1], -7)
    end

    test "large negative transpositions" do
      assert ~n[C4] == transpose!(~n[C6], -24)
      assert ~n[G2] == transpose!(~n[G5], -36)
      assert ~n[A3] == transpose!(~n[A7], -48)
      assert ~n[E3] == transpose!(~n[E8], -60)
    end

    test "single semitone down" do
      assert ~n[C#4] == transpose!(~n[D4], -1)
      assert ~n[E4] == transpose!(~n[F4], -1)
      assert ~n[A#4] == transpose!(~n[B4], -1)
      assert ~n[A5] == transpose!(~n[A#5], -1)
    end

    test "C and B edge cases - downward" do
      assert ~n[B3] == transpose!(~n[C4], -1)
      assert ~n[B1] == transpose!(~n[C3], -13)
      assert ~n[B4] == transpose!(~n[C#5], -2)
      assert ~n[B4] == transpose!(~n[D5], -3)
    end

    test "mixed positive and negative with same note" do
      note = ~n[E4]
      assert ~n[B4] == transpose!(note, 7)
      assert ~n[C#4] == transpose!(note, -3)
      assert ~n[E4] == note |> transpose!(12) |> transpose!(-12)
    end

    test "round trip transpositions" do
      assert ~n[F4] ==
               ~n[F4] |> transpose!(7) |> transpose!(-7)

      assert ~n[G#5] ==
               ~n[G#5] |> transpose!(24) |> transpose!(-24)

      assert ~n[C3] ==
               ~n[C3] |> transpose!(-12) |> transpose!(12)
    end
  end

  describe "transpose/2 out of bound" do
    test "transposing above octave 9 returns error" do
      assert {:error, reason} = transpose(~n[B9], 1)
      assert reason =~ "Failed to create newly transoped note"

      assert {:error, reason} = transpose(~n[C9], 12)
      assert reason =~ "Failed to create newly transoped note"

      assert {:error, reason} = transpose(~n[G#9], 5)
      assert reason =~ "Failed to create newly transoped note"
    end

    test "transposing below octave 0 returns error" do
      assert {:error, reason} = transpose(~n[C0], -1)
      assert reason =~ "Failed to create newly transoped note"

      assert {:error, reason} = transpose(~n[C0], -12)
      assert reason =~ "Failed to create newly transoped note"

      assert {:error, reason} = transpose(~n[A0], -10)
      assert reason =~ "Failed to create newly transoped note"
    end

    test "large transposition out of upper bound returns error" do
      assert {:error, reason} = transpose(~n[C8], 25)
      assert reason =~ "Failed to create newly transoped note"

      assert {:error, reason} = transpose(~n[A5], 60)
      assert reason =~ "Failed to create newly transoped note"
    end

    test "large transposition out of lower bound returns error" do
      assert {:error, reason} = transpose(~n[C1], -25)
      IO.puts(reason)
      assert reason =~ "Failed to create newly transoped note"

      assert {:error, reason} = transpose(~n[A2], -36)
      assert reason =~ "Failed to create newly transoped note"
    end
  end
end
