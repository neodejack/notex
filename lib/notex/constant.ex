defmodule Notex.Constant do
  @moduledoc false
  @all_note_names ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
  @all_octaves 0..9

  @flat_to_sharp_map %{
    "Db" => "C#",
    "Eb" => "D#",
    "Gb" => "F#",
    "Ab" => "G#",
    "Bb" => "A#"
  }

  # Enharmonics that cross or sit at the half-step boundaries (B/C, E/F)
  @enharmonic_map %{
    "Cb" => {"B", -1},
    "Fb" => {"E", 0},
    "B#" => {"C", 1},
    "E#" => {"F", 0}
  }

  @relative_semitones %{
    one: 0,
    sharp_one: 1,
    flat_two: 1,
    two: 2,
    sharp_two: 3,
    flat_three: 3,
    three: 4,
    four: 5,
    sharp_four: 6,
    flat_five: 6,
    five: 7,
    sharp_five: 8,
    flat_six: 8,
    six: 9,
    sharp_six: 10,
    flat_seven: 10,
    seven: 11
  }

  @note_name_indexes @all_note_names
                     |> Enum.with_index()
                     |> Map.new()
  @note_name_count length(@all_note_names)

  def relative_semitones, do: @relative_semitones
  def all_note_names, do: @all_note_names
  def all_octaves, do: @all_octaves
  def flat_to_sharp_map, do: @flat_to_sharp_map
  def enharmonic_map, do: @enharmonic_map
  def note_name_indexes, do: @note_name_indexes
  def note_name_count, do: @note_name_count
end
