defmodule Notex.Constant do
  @moduledoc false
  @all_note_names ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
  @all_octaves 0..9

  @note_name_indexes @all_note_names
                     |> Enum.with_index()
                     |> Map.new()

  @note_name_count length(@all_note_names)

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

  @relatives %{
    one: [semitones: 0, name: "1"],
    sharp_one: [semitones: 1, name: "#1"],
    flat_two: [semitones: 1, name: "b2"],
    two: [semitones: 2, name: "2"],
    sharp_two: [semitones: 3, name: "#2"],
    flat_three: [semitones: 3, name: "b3"],
    three: [semitones: 4, name: "3"],
    four: [semitones: 5, name: "4"],
    sharp_four: [semitones: 6, name: "#4"],
    flat_five: [semitones: 6, name: "b5"],
    five: [semitones: 7, name: "5"],
    sharp_five: [semitones: 8, name: "#5"],
    flat_six: [semitones: 8, name: "b6"],
    six: [semitones: 9, name: "6"],
    sharp_six: [semitones: 10, name: "#6"],
    flat_seven: [semitones: 10, name: "b7"],
    seven: [semitones: 11, name: "7"]
  }

  @relative_semitones Map.new(@relatives, fn {k, v} -> {k, v[:semitones]} end)
  @relative_names Map.new(@relatives, fn {k, v} -> {k, v[:name]} end)

  def relative_semitones, do: @relative_semitones
  def relative_names, do: @relative_names
  def all_note_names, do: @all_note_names
  def all_octaves, do: @all_octaves
  def flat_to_sharp_map, do: @flat_to_sharp_map
  def enharmonic_map, do: @enharmonic_map
  def note_name_indexes, do: @note_name_indexes
  def note_name_count, do: @note_name_count
end
