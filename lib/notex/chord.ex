defmodule Notex.Chord do
  @moduledoc false
  alias __MODULE__
  alias Notex.Constant
  alias Notex.Note

  @type octave_offset() :: integer()

  @type t() :: %Chord{
          base_note: Note.t(),
          voicings: [{Constant.interval_id(), [octave_offset()]}]
        }

  @enforce_keys [:base_note, :voicings]
  defstruct [:base_note, :voicings]

  @spec new(Note.t()) :: t()
  def new(%Note{} = base_note) do
    add(%Chord{base_note: base_note, voicings: []}, :one, 0)
  end

  @spec add(t(), Constant.interval_id(), octave_offset()) :: t()
  def add(%Chord{voicings: voicings} = chord, interval, octave_offset) do
    updated_voicings =
      Keyword.update(voicings, interval, [octave_offset], &Enum.uniq([octave_offset | &1]))

    %{chord | voicings: updated_voicings}
  end

  @spec omit(t(), Constant.interval_id(), octave_offset()) :: t()
  def omit(%Chord{voicings: voicings} = chord, interval, octave_offset) do
    case Keyword.fetch(voicings, interval) do
      :error ->
        chord

      {:ok, octave_offsets} ->
        case List.delete(octave_offsets, octave_offset) do
          [] -> %{chord | voicings: Keyword.delete(voicings, interval)}
          remaining_offsets -> %{chord | voicings: Keyword.put(voicings, interval, remaining_offsets)}
        end
    end
  end

  @spec notes(t()) :: {:ok, [Note.t()]} | {:error, binary()}
  def notes(%Chord{base_note: base_note, voicings: voicings}) do
    interval_semitones = Constant.interval_semitones()

    semitones =
      for {interval, octave_offsets} <- voicings,
          octave_offset <- Enum.reverse(octave_offsets) do
        {Map.fetch!(interval_semitones, interval) + octave_semitones(octave_offset), {interval, octave_offset}}
      end

    semitones
    |> Enum.reduce_while({:ok, []}, fn {semitone, {interval, octave_offset}}, {:ok, acc} ->
      case Note.transpose(base_note, semitone) do
        {:ok, note} ->
          {:cont, {:ok, [note | acc]}}

        {:error, reason} ->
          error = "failed to build note for #{inspect({interval, octave_offset})}: #{reason}"
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
