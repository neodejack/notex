defmodule Notex.Chord do
  @moduledoc false
  alias __MODULE__
  alias Notex.Constant
  alias Notex.Note

  ## octave is any integer between -10..10
  @type octave_move() :: integer()

  @type t() :: %Chord{
          base_note: Note.t(),
          intervals: [{Constant.interval_id(), [octave_move()]}]
        }

  @enforce_keys [:base_note, :intervals]
  defstruct [:base_note, :intervals]

  @spec new(Note.t()) :: t()
  def new(%Note{} = base_note) do
    add(%Chord{base_note: base_note, intervals: []}, :one, 0)
  end

  @spec add(t(), Constant.interval_id(), octave_move()) :: t()
  def add(%Chord{intervals: intervals} = chord, interval, octave_move) do
    updated_intervals =
      Keyword.update(intervals, interval, [octave_move], &Enum.uniq([octave_move | &1]))

    %{chord | intervals: updated_intervals}
  end

  @spec omit(t(), Constant.interval_id(), octave_move()) :: t()
  def omit(%Chord{intervals: intervals} = chord, interval, octave_move) do
    case Keyword.fetch(intervals, interval) do
      :error ->
        chord

      {:ok, octave_moves} ->
        case List.delete(octave_moves, octave_move) do
          [] -> %{chord | intervals: Keyword.delete(intervals, interval)}
          remaining_moves -> %{chord | intervals: Keyword.put(intervals, interval, remaining_moves)}
        end
    end
  end

  @spec notes(t()) :: {:ok, [Note.t()]} | {:error, binary()}
  def notes(%Chord{base_note: base_note, intervals: intervals}) do
    interval_semitones = Constant.interval_semitones()

    semitones =
      for {interval, octave_moves} <- intervals,
          octave_move <- Enum.reverse(octave_moves) do
        {Map.fetch!(interval_semitones, interval) + octave_semitones(octave_move), {interval, octave_move}}
      end

    semitones
    |> Enum.reduce_while({:ok, []}, fn {semitone, {interval, octave_move}}, {:ok, acc} ->
      case Note.transpose(base_note, semitone) do
        {:ok, note} ->
          {:cont, {:ok, [note | acc]}}

        {:error, reason} ->
          error = "failed to build note for #{inspect({interval, octave_move})}: #{reason}"
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
