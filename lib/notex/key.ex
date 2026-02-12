defmodule Notex.Key do
  @moduledoc false
  alias Notex.Constant
  alias Notex.Note

  @doc """
  return a list of notes within this key []
  """
  @spec major(%Note{}) :: [%Note{}]
  def major(tonic) do
    tonic
    |> rotate_key_with_tonic_as_base()
    |> filter_item_with_index(major_key_semitones())
  end

  @doc """
  return a list with the notes represented by the number of semitones they need to be from root
  """
  def major_key_semitones, do: [0, 2, 4, 5, 7, 9, 11]

  defp rotate_key_with_tonic_as_base(tonic) do
    all_notes =
      Enum.map(Constant.all_note_names(), fn note_name -> Note.new!(note_name, tonic.octave) end)

    {notes_before_tonic, notes_after_tonic} =
      all_notes
      |> Enum.find_index(&Note.equal?(&1, tonic))
      |> ensure_index!()
      |> then(&Enum.split(all_notes, &1))

    # we are attching notes_before_tonic to the end of notes_after_tonic
    # so we need the octave to be tonic.octave + 1
    notes_before_tonic = Enum.map(notes_before_tonic, &Note.new!(&1.note_name, &1.octave + 1))

    notes_after_tonic ++ notes_before_tonic
  end

  defp ensure_index!(index) do
    case index do
      nil -> raise "no notes found"
      i when is_number(i) -> i
    end
  end

  defp filter_item_with_index(list, index) do
    indices = MapSet.new(index)

    list
    |> Enum.with_index()
    |> Enum.filter(fn {_term, i} -> i in indices end)
    |> Enum.map(fn {term, _i} -> term end)
  end
end
