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
      Keyword.update(notes, relative, [octave_move], &(&1 ++ [octave_move]))

    %{chord | notes: updated_notes}
  end

  @spec omit(t(), Constant.relative_atoms(), octave_move()) :: t()
  def omit(%Chord{} = chord, relative, octave_move) do
    chord
  end

  @spec notes(t()) :: {:ok, [Note.t()]} | {:error, binary()}
  def notes(%Chord{base_note: base_note, notes: notes}) do
    semitones =
      for {relative, octacve_move} <- notes do
        Map.fetch!(Constant.relative_semitones(), relative) + octave_semitones(octacve_move)
      end

    {notes, ok?} =
      Enum.map_reduce(semitones, true, fn
        semitone, true ->
          case Note.transpose(base_note, semitone) do
            {:ok, note} -> {note, true}
            {:error, _msg} -> {nil, false}
          end

        _, false ->
          {nil, false}
      end)

    if ok? do
      {:ok, notes}
    else
      {:error, "error when building notes"}
    end
  end

  defp transform_notes do
  end

  def octave_semitones(octave) when is_integer(octave) do
    octave * 12
  end

  def maj(%Note{} = base_note) do
    base_note
    |> new()
    |> add(:three, 0)
    |> add(:five, 0)
  end
end
