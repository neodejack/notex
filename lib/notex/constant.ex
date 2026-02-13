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
  def all_note_names, do: @all_note_names
  def all_octaves, do: @all_octaves
  def flat_to_sharp_map, do: @flat_to_sharp_map
  def enharmonic_map, do: @enharmonic_map
end
