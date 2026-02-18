defmodule Notex.Scale do
  @moduledoc """
  A scale is a a list of Note that follows a harmonic pattern.

  A scale is constructed by selecting notes from the chromatic scale starting
  at the given tonic, based on the interval pattern defined by a `Notex.ScaleType`
  module.

  ## Examples

      iex> import Notex.Note
      iex> Notex.Scale.notes!(~n[C4], :major)
      [~n[C4], ~n[D4], ~n[E4], ~n[F4], ~n[G4], ~n[A4], ~n[B4]]
      iex> Notex.Scale.notes!(~n[A4], :minor)
      [~n[A4], ~n[B4], ~n[C5], ~n[D5], ~n[E5], ~n[F5], ~n[G5]]

  """

  alias Notex.Constant
  alias Notex.Note
  alias Notex.ScaleType

  @doc """
  Returns the notes of a scale built from the given `tonic` and `scale_type`.

  `scale_type` accepts:

    * A full module name (e.g. `Notex.ScaleType.Major`) — used as-is.
    * A shorthand atom (e.g. `:major` or `:Major`) — capitalized and appended
      to a built-in scale type under `Notex.ScaleType`. For example, `:major`
      becomes `Notex.ScaleType.Major`.
    * Any custom module implementing the `Notex.ScaleType` behaviour.

  Returns `{:ok, notes}` on success or `{:error, reason}` on failure.

  ## Examples

      iex> Notex.Scale.notes(Notex.Note.new!("C", 4), :major)
      {:ok, [~n[C4], ~n[D4], ~n[E4], ~n[F4], ~n[G4], ~n[A4], ~n[B4]]}

      iex> Notex.Scale.notes(Notex.Note.new!("C", 4), Notex.ScaleType.Major)
      {:ok, [~n[C4], ~n[D4], ~n[E4], ~n[F4], ~n[G4], ~n[A4], ~n[B4]]}

      iex> Notex.Scale.notes(Notex.Note.new!("C", 4), :nonexistent)
      {:error, "scale type :nonexistent not found"}

  """
  @spec notes(Note.t(), atom()) :: {:ok, [Note.t()]} | {:error, String.t()}
  def notes(tonic, scale_type) when is_atom(scale_type) do
    with {:ok, resolved} <- resolve_scale_type(scale_type),
         {:ok, all_notes} <- all_notes_from_tonic(tonic) do
      notes =
        resolved
        |> ScaleType.relative_semitones()
        |> take_scale_note(all_notes)

      {:ok, notes}
    end
  end

  @doc """
  Bang variant of `notes/2`. Returns the list of notes directly or raises `ArgumentError`.

  ## Examples

      iex> import Notex.Note
      iex> Notex.Scale.notes!(~n[C4], :major)
      [~n[C4], ~n[D4], ~n[E4], ~n[F4], ~n[G4], ~n[A4], ~n[B4]]

  """
  @spec notes!(Note.t(), module() | atom()) :: [Note.t()]
  def notes!(tonic, scale_type) when is_atom(scale_type) do
    case notes(tonic, scale_type) do
      {:ok, notes} -> notes
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  defp resolve_scale_type(scale_type) do
    case Code.ensure_loaded(scale_type) do
      {:error, _} ->
        capitalized = scale_type |> Atom.to_string() |> String.capitalize() |> String.to_atom()
        module = Module.concat(ScaleType, capitalized)

        case Code.ensure_loaded(module) do
          {:module, ^module} -> {:ok, module}
          {:error, _} -> {:error, "scale type #{inspect(scale_type)} not found"}
        end

      {:module, ^scale_type} ->
        {:ok, scale_type}
    end
  end

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
