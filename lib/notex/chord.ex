defmodule Notex.Chord do
  @moduledoc false
  use Notex

  alias __MODULE__
  alias Notex.Constant
  alias Notex.Note

  @type chord_step() :: (t() -> {:ok, t()} | {:error, binary()})

  @type octave_offset() :: integer()

  @type step_name() :: atom()

  @type t() :: %Chord{
          voicings: [{Constant.interval_id(), [octave_offset()]}],
          steps: [{step_name(), chord_step()}]
        }

  @enforce_keys [:voicings, :steps]
  defstruct [:voicings, :steps]

  def new do
    %Chord{
      voicings: [],
      steps: []
    }
  end

  @spec append_step(t(), step_name(), chord_step()) :: t()
  def append_step(chord, name, step) when is_atom(name) do
    %{chord | steps: [{name, step} | chord.steps]}
  end

  @spec build(t()) :: {:ok, t()} | {:error, binary()}
  def build(%Chord{steps: steps}) do
    steps
    |> Enum.reverse()
    |> Enum.reduce_while({:ok, new()}, fn {name, step}, {:ok, chord_acc} ->
      case run_step(step, chord_acc) do
        {:ok, %Chord{} = chord} -> {:cont, {:ok, chord}}
        {:error, msg} when is_binary(msg) -> {:halt, {:error, "error when building step: #{inspect(name)}\n#{msg}"}}
        %Chord{} = chord -> {:cont, {:ok, chord}}
      end
    end)
  end

  defp run_step(step, state) when is_function(step, 1) do
    step.(state)
  end

  @spec put_intervals(t(), step_name() | binary(), [Constant.interval_id()] | Constant.interval_id(), [octave_offset()]) ::
          t()
  def put_intervals(chord, name, intervals, voicing \\ [0])

  def put_intervals(%Chord{} = chord, name, intervals, voicing) when is_binary(name) do
    put_intervals(chord, String.to_atom(name), intervals, voicing)
  end

  def put_intervals(%Chord{} = chord, _name, [], _voicing) do
    chord
  end

  def put_intervals(%Chord{} = chord, name, [interval | rest], voicing)
      when is_atom(name) and is_interval(interval) and is_list(voicing) do
    chord
    |> append_step(name, &put_interval_step(&1, interval, voicing))
    |> put_intervals(name, rest, voicing)
  end

  def put_intervals(%Chord{} = chord, name, interval, voicing)
      when is_atom(name) and is_interval(interval) and is_list(voicing) do
    append_step(chord, name, &put_interval_step(&1, interval, voicing))
  end

  defp put_interval_step(%Chord{voicings: voicings} = chord, interval, voicing)
       when is_interval(interval) and is_list(voicing) do
    %{chord | voicings: Keyword.put(voicings, interval, voicing)}
  end

  @spec drop_intervals(t(), step_name() | binary(), [Constant.interval_id()] | Constant.interval_id()) :: t()
  def drop_intervals(%Chord{} = chord, name, intervals) when is_binary(name) do
    drop_intervals(chord, String.to_atom(name), intervals)
  end

  def drop_intervals(%Chord{} = chord, _name, []) do
    chord
  end

  def drop_intervals(%Chord{} = chord, name, [interval | rest]) when is_atom(name) and is_interval(interval) do
    chord
    |> append_step(name, &drop_interval_step(&1, interval))
    |> drop_intervals(name, rest)
  end

  def drop_intervals(%Chord{} = chord, name, interval) when is_atom(name) and is_interval(interval) do
    append_step(chord, name, &drop_interval_step(&1, interval))
  end

  defp drop_interval_step(%Chord{voicings: voicings} = chord, interval) do
    %{chord | voicings: Keyword.delete(voicings, interval)}
  end

  @spec update_voicing(
          t(),
          step_name() | binary(),
          Constant.interval_id(),
          (existing :: [octave_offset()] -> new :: [octave_offset()])
        ) ::
          t()

  def update_voicing(%Chord{} = chord, name, interval, func)
      when is_binary(name) and is_interval(interval) and is_function(func, 1) do
    update_voicing(chord, String.to_atom(name), interval, func)
  end

  def update_voicing(%Chord{} = chord, name, interval, func)
      when is_atom(name) and is_interval(interval) and is_function(func, 1) do
    append_step(chord, name, &update_voicing_step(&1, interval, func))
  end

  defp update_voicing_step(%Chord{voicings: voicings} = chord, interval, func)
       when is_interval(interval) and is_function(func, 1) do
    case Keyword.fetch(voicings, interval) do
      {:ok, interval_octaves} ->
        {:ok,
         %{
           chord
           | voicings: Keyword.put(voicings, interval, func.(interval_octaves))
         }}

      :error ->
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
