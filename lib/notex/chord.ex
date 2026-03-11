defmodule Notex.Chord do
  @moduledoc false
  use Notex

  alias __MODULE__
  alias Notex.Constant
  alias Notex.Note

  @type step_func() :: (t() -> {:ok, t()} | {:error, binary()})

  @type octave_offset() :: integer()

  @type step_name() :: atom()

  @type t() :: %Chord{
          voicings: [{Constant.interval_id(), [octave_offset()]}],
          steps: [{step_name(), step_func()}]
        }

  @enforce_keys [:voicings, :steps]
  defstruct [:voicings, :steps]

  @spec new(
          t()
          | (-> t())
          | {module(), atom(), [term()]}
          | atom()
        ) ::
          {:ok, t()} | {:error, binary()}
  def new(%Chord{} = chord), do: build(chord)

  def new(fun) when is_function(fun, 0), do: build(fun.())

  def new({mod, fun, args}) when is_atom(mod) and is_atom(fun) and is_list(args) do
    mod |> apply(fun, args) |> build()
  end

  def new(name) when is_atom(name) do
    Chord.Builtin |> apply(name, []) |> build()
  rescue
    UndefinedFunctionError -> {:error, "chord name provided can't be found in built-in chords: #{inspect(name)}"}
  end

  @spec base() :: t()
  def base do
    %Chord{
      voicings: [],
      steps: []
    }
  end

  @spec append_step(t(), step_name(), step_func()) :: t()
  def append_step(chord, name, step) when is_atom(name) do
    %{chord | steps: [{name, step} | chord.steps]}
  end

  @spec build(t()) :: {:ok, t()} | {:error, binary()}
  def build(%Chord{steps: []} = chord), do: {:ok, chord}

  def build(%Chord{voicings: voicings, steps: steps}) when is_list(steps) and [] != steps do
    seed_chord = %{base() | voicings: voicings}

    steps
    |> Enum.reverse()
    |> Enum.reduce_while({:ok, seed_chord}, fn {name, step}, {:ok, chord_acc} ->
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

  def put_intervals(%Chord{} = chord, name, intervals, voicing)
      when is_atom(name) and is_list(voicing) and is_list(intervals) do
    append_step(chord, name, &put_interval_step(&1, intervals, voicing))
  end

  def put_intervals(%Chord{} = chord, name, interval, voicing)
      when is_atom(name) and is_list(voicing) and is_interval(interval) do
    append_step(chord, name, &put_interval_step(&1, interval, voicing))
  end

  defp put_interval_step(%Chord{} = chord, [], _voicing) do
    chord
  end

  defp put_interval_step(%Chord{} = chord, [interval | rest], voicing) when is_interval(interval) and is_list(voicing) do
    chord
    |> put_interval_step(interval, voicing)
    |> put_interval_step(rest, voicing)
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

  def drop_intervals(%Chord{} = chord, name, intervals) when is_atom(name) and is_list(intervals) do
    append_step(chord, name, &drop_interval_step(&1, intervals))
  end

  def drop_intervals(%Chord{} = chord, name, interval) when is_atom(name) and is_interval(interval) do
    append_step(chord, name, &drop_interval_step(&1, interval))
  end

  defp drop_interval_step(%Chord{} = chord, []) do
    chord
  end

  defp drop_interval_step(%Chord{} = chord, [interval | rest]) when is_interval(interval) do
    chord
    |> drop_interval_step(interval)
    |> drop_interval_step(rest)
  end

  defp drop_interval_step(%Chord{voicings: voicings} = chord, interval) when is_interval(interval) do
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

  @doc """
  Returns the notes produced by a chord with a base note.

  The chord is built via `build/1` before note derivation, and the resulting
  notes are sorted by absolute pitch.

  Returns `{:ok, notes}` on success, or `{:error, reason}` when building or
  transposition fails.

  ## Examples

      iex> chord = Notex.Chord.put_intervals(Notex.Chord.base(), :add_triad, [:one, :three, :five])
      iex> Notex.Chord.notes(chord, ~n[C4])
      {:ok, [~n[C4], ~n[E4], ~n[G4]]}

  """
  @spec notes(t(), Note.t()) :: {:ok, [Note.t()]} | {:error, binary()}
  def notes(%Chord{} = chord, %Note{} = base_note) do
    with {:ok, %Chord{voicings: voicings}} <- build(chord) do
      note_targets = note_targets(voicings)
      transpose_note_targets(base_note, note_targets)
    end
  end

  defp note_targets(voicings) do
    interval_semitones = Constant.interval_semitones()

    for {interval, octave_offsets} <- voicings,
        octave_offset <- octave_offsets do
      semitone = Map.fetch!(interval_semitones, interval) + octave_semitones(octave_offset)
      {semitone, interval, octave_offset}
    end
  end

  defp transpose_note_targets(base_note, note_targets) do
    note_targets
    |> Enum.reduce_while({:ok, []}, fn {semitone, interval, octave_offset}, {:ok, acc} ->
      case Note.transpose(base_note, semitone) do
        {:ok, note} ->
          {:cont, {:ok, [note | acc]}}

        {:error, reason} ->
          error = "failed to build note for #{inspect({interval, octave_offset})}: #{reason}"
          {:halt, {:error, error}}
      end
    end)
    |> sort_transposed_notes()
  end

  defp sort_transposed_notes({:ok, notes}) do
    sorted_notes = Enum.sort(notes, &(Note.compare(&1, &2) in [:lt, :eq]))

    {:ok, sorted_notes}
  end

  defp sort_transposed_notes({:error, reason}) do
    {:error, reason}
  end

  defp octave_semitones(octave) when is_integer(octave) do
    octave * 12
  end
end
