defmodule Notex.Scale do
  @moduledoc false
  alias Notex.Constant
  alias Notex.Note

  @spec notes(module(), %Note{}) :: {:ok, [%Note{}]} | {:error, binary()}
  def notes(scale_type, tonic) when is_atom(scale_type) do
    with {:ok, all_notes} <- all_notes_from_tonic(tonic) do
      notes =
        scale_type
        |> semitones()
        |> take_scale_note(all_notes)

      {:ok, notes}
    end
  end

  @spec notes!(module(), %Note{}) :: [%Note{}]
  def notes!(scale_type, tonic) when is_atom(scale_type) do
    case notes(scale_type, tonic) do
      {:ok, notes} -> notes
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @spec semitones(module()) :: [integer()]
  def semitones(scale_type) do
    for r <- scale_type.relative_notes() do
      Map.fetch!(Constant.relative_semitones(), r)
    end
  end

  @spec notes(module(), %Note{}) :: {:ok, [%Note{}]} | {:error, binary()}
  defp all_notes_from_tonic(tonic) do
    # TODO: consider using Note.new/2 to directly check if this function will fail or succeed
    # instead of using the hack function valid_tonic?()
    if valid_tonic?(tonic) do
      all_notes =
        Enum.map(Constant.all_note_names(), fn note_name ->
          Note.new!(note_name, tonic.octave)
        end)

      # TODO: this section can be refactored to use Notes.compare once we have that primitive
      {notes_before_tonic, notes_after_tonic} =
        all_notes
        |> Enum.find_index(&Note.equal?(&1, tonic))
        |> ensure_index!()
        |> then(&Enum.split(all_notes, &1))

      # we are attching notes_before_tonic to the end of notes_after_tonic
      # so we need the octave to be tonic.octave + 1
      next_octave_notes =
        Enum.map(notes_before_tonic, &Note.new!(&1.note_name, &1.octave + 1))

      {:ok, notes_after_tonic ++ next_octave_notes}
    else
      {:error, "tonic provided is not valid for constructing a scale"}
    end
  end

  defp valid_tonic?(tonic) do
    highest_valid_notename = hd(Constant.all_note_names())
    highest_valid_octave = Constant.all_octaves() |> Enum.to_list() |> List.last()

    case Note.compare(tonic, Note.new!(highest_valid_notename, highest_valid_octave)) do
      :gt -> false
      _ -> true
    end
  end

  defp ensure_index!(index) do
    case index do
      nil -> raise "no notes found"
      i when is_number(i) -> i
    end
  end

  defp take_scale_note(semitones_to_take, all_notes) do
    all_notes
    |> Enum.with_index()
    |> Enum.flat_map(fn {note, semitone} ->
      if semitone in semitones_to_take do
        [note]
      else
        []
      end
    end)
  end
end
