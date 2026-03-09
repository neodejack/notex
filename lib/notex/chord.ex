defmodule Notex.Chord do
  @moduledoc false
  use Notex

  alias __MODULE__
  alias Notex.Constant
  alias Notex.Note

  @type chord_step() :: (t() -> {:ok, t()} | {:error, binary()})

  @type octave_offset() :: integer()

  @type t() :: %Chord{voicings: [{Constant.interval_id(), [octave_offset()]}], steps: [chord_step()]}

  @enforce_keys [:voicings, :steps]
  defstruct [:voicings, :steps]

  def new do
    %Chord{
      voicings: [],
      steps: []
    }
  end

  @spec append_step(t(), chord_step()) :: t()
  def append_step(chord, step) do
    %{
      chord
      | steps: [step | chord.steps]
    }
  end

  @spec build(t()) :: {:ok, t()} | {:error, binary()}
  def build(%Chord{steps: steps}) do
    steps
    |> Enum.reverse()
    |> Enum.reduce_while({:ok, new()}, fn step, {:ok, chord_acc} ->
      case run_step(step, chord_acc) do
        {:ok, %Chord{} = chord} -> {:cont, {:ok, chord}}
        {:error, msg} when is_binary(msg) -> {:halt, {:error, msg}}
        %Chord{} = chord -> {:cont, {:ok, chord}}
      end
    end)
  end

  defp run_step(step, state) when is_function(step, 1) do
    step.(state)
  end

  @spec put_intervals(t(), [Constant.interval_id()] | Constant.interval_id(), [octave_offset()]) :: t()
  def put_intervals(chord, intervals, voicing \\ [0])

  def put_intervals(%Chord{} = chord, [], _voicing) do
    chord
  end

  def put_intervals(%Chord{} = chord, [interval | rest], voicing) when is_interval(interval) and is_list(voicing) do
    chord
    |> append_step(&put_interval_step(&1, interval, voicing))
    |> put_intervals(rest, voicing)
  end

  def put_intervals(%Chord{} = chord, interval, voicing) when is_interval(interval) and is_list(voicing) do
    append_step(chord, &put_interval_step(&1, interval, voicing))
  end

  defp put_interval_step(%Chord{voicings: voicings} = chord, interval, voicing)
       when is_interval(interval) and is_list(voicing) do
    %{chord | voicings: Keyword.put(voicings, interval, voicing)}
  end

  @spec drop_intervals(t(), [Constant.interval_id()] | Constant.interval_id()) :: t()
  def drop_intervals(%Chord{} = chord, []) do
    chord
  end

  def drop_intervals(%Chord{} = chord, [interval | rest]) when is_interval(interval) do
    chord
    |> append_step(&drop_interval_step(&1, interval))
    |> drop_intervals(rest)
  end

  def drop_intervals(%Chord{} = chord, interval) when is_interval(interval) do
    append_step(chord, &drop_interval_step(&1, interval))
  end

  defp drop_interval_step(%Chord{voicings: voicings} = chord, interval) do
    %{chord | voicings: Keyword.delete(voicings, interval)}
  end

  @spec set_voicing(t(), Constant.interval_id(), [octave_offset()]) :: t()
  def set_voicing(%Chord{} = chord, interval, voicing) when is_interval(interval) do
    append_step(chord, &set_voicing_step(&1, interval, voicing))
  end

  defp set_voicing_step(%Chord{voicings: voicings} = chord, interval, voicing) do
    if Keyword.has_key?(voicings, interval) do
      {:ok, %{chord | voicings: Keyword.put(voicings, interval, voicing)}}
    else
      {:error, "interval #{inspect(interval)} does not exist in chord voicings"}
    end
  end

  @spec notes(t(), Note.t()) :: {:ok, [Note.t()]} | {:error, binary()}
  def notes(%Chord{voicings: voicings}, %Note{} = base_note) do
    semitones =
      for {interval, octave_offsets} <- voicings,
          octave_offset <- Enum.reverse(octave_offsets) do
        {Map.fetch!(Constant.interval_semitones(), interval) + octave_semitones(octave_offset), {interval, octave_offset}}
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
end
