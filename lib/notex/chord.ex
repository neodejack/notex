defmodule Notex.Chord do
  @moduledoc false
  alias __MODULE__
  alias Notex.Constant
  alias Notex.Note

  ## octave is any integer between -10..10
  @type octave_move() :: integer()

  @type t() :: %Chord{
          base_note: Note.t(),
          notes: [{Constant.relative_atoms(), [octave_move()]}]
        }

  @enforce_keys [:base_note, :notes]
  defstruct [:base_note, :notes]

  @spec new(Note.t()) :: t()
  def new(%Note{} = base_note) do
    add(%Chord{base_note: base_note, notes: []}, :one, 0)
  end

  @spec add(t(), Constant.relative_atoms(), octave_move()) :: t()
  def add(%Chord{notes: notes} = chord, relative, octave_move) do
    updated_notes =
      Keyword.update(notes, relative, [octave_move], &Enum.uniq([octave_move | &1]))

    %{chord | notes: updated_notes}
  end

  @spec omit(t(), Constant.relative_atoms(), octave_move()) :: t()
  def omit(%Chord{notes: notes} = chord, relative, octave_move) do
    case Keyword.fetch(notes, relative) do
      :error ->
        chord

      {:ok, octave_moves} ->
        case List.delete(octave_moves, octave_move) do
          [] -> %{chord | notes: Keyword.delete(notes, relative)}
          remaining_moves -> %{chord | notes: Keyword.put(notes, relative, remaining_moves)}
        end
    end
  end

  @spec notes(t()) :: {:ok, [Note.t()]} | {:error, binary()}
  def notes(%Chord{base_note: base_note, notes: notes}) do
    relative_semitones = Constant.relative_semitones()

    semitones =
      for {relative, octave_moves} <- notes,
          octave_move <- Enum.reverse(octave_moves) do
        {Map.fetch!(relative_semitones, relative) + octave_semitones(octave_move), {relative, octave_move}}
      end

    semitones
    |> Enum.reduce_while({:ok, []}, fn {semitone, {relative, octave_move}}, {:ok, acc} ->
      case Note.transpose(base_note, semitone) do
        {:ok, note} ->
          {:cont, {:ok, [note | acc]}}

        {:error, reason} ->
          error = "failed to build note for #{inspect({relative, octave_move})}: #{reason}"
          {:halt, {:error, error}}
      end
    end)
    |> then(fn
      {:ok, built_notes} -> {:ok, Enum.reverse(built_notes)}
      {:error, reason} -> {:error, reason}
    end)
  end

  defp octave_semitones(octave) when is_integer(octave) do
    octave * 12
  end

  def maj(%Note{} = base_note) do
    base_note
    |> new()
    |> add(:three, 0)
    |> add(:five, 0)
  end
end
