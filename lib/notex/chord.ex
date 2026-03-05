defmodule Notex.Chord do
  @moduledoc """
  Builds, presets, and transforms chords

  A `Notex.Chord` stores two pieces of state:

    * `:voicings` — a keyword list mapping interval IDs (such as `:one` or
      `:flat_three`) to octave offsets.
    * `:steps` — a queue of named transformation functions applied during `build/1`.

  The **Chord shape transform API** consists of `put_intervals/4`,
  `drop_intervals/3`, and `update_voicing/4`.
  These functions register steps. The steps are executed in insertion order when you call
  `build/1`, or implicitly when calling `notes/2`.

  `notes/2` applies a chord to a base note (a `Notex.Note`) and returns the resulting notes sorted by pitch.

  This module also includes built-in chord constructors such as `major7/0`
  and transformation helpers such as `add13/1`.

  ## Examples

      iex> use Notex
      iex> chord_shape =
      ...>   Chord.base()
      ...>   |> Chord.put_intervals(:add_triad, [:one, :three, :five])
      iex> Chord.notes(chord_shape, ~n[C4])
      {:ok, [~n[C4], ~n[E4], ~n[G4]]}

      iex> {:ok, chord} = Chord.major7()
      ...> |> Chord.add13()
      ...> |> Chord.update_voicing(:drop_root, :one, fn [existing] -> [existing - 2] end)
      ...> |> Chord.new()
      iex> Chord.notes(chord, ~n[C4])
      {:ok, [~n[C2], ~n[E4], ~n[G4], ~n[B4], ~n[A5]]}

  """
  use Notex

  alias __MODULE__
  alias Notex.Constant
  alias Notex.Note
  alias Notex.Types

  @typedoc """
  A named transformation step executed by `build/1`.

  The step receives a `t:Notex.Chord.t/0` and returns either an updated chord,
  `{:ok, chord}`, or `{:error, reason}`.
  """
  @type step_func() :: (t() -> {:ok, t()} | {:error, binary()})

  @typedoc "An octave shift (in octaves) applied to an interval when deriving notes."
  @type octave_offset() :: integer()

  @typedoc "A human-readable identifier used to label a chord-building step."
  @type step_name() :: atom()

  @typedoc "The chord builder struct used by `Notex.Chord` APIs."
  @type t() :: %Chord{
          voicings: [{Types.interval_id(), [octave_offset()]}],
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
  @doc """
  Builds a chord from a supported chord shape input.

  Accepted inputs:

    * A `t:Notex.Chord.t/0` value.
    * A zero-arity function returning a `t:Notex.Chord.t/0`.
    * An MFA tuple `{module, function, args}` that returns a `t:Notex.Chord.t/0`.
    * A built-in chord name atom from `Notex.Chord`.

  Returns `{:ok, chord}` when the shape builds successfully, or
  `{:error, reason}` for unknown built-in chord names.

  ## Examples

      iex> use Notex
      iex> Chord.new(:major)
      {:ok, %Notex.Chord{voicings: [five: [0], three: [0], one: [0]], steps: []}}

      iex> shape = fn -> Chord.put_intervals(Chord.base(), :add_power, [:one, :five]) end
      iex> Chord.new(shape)
      {:ok, %Notex.Chord{voicings: [five: [0], one: [0]], steps: []}}

      iex> Chord.new(:unknown)
      {:error, "chord name provided can't be found in built-in chords: :unknown"}

  """
  def new(%Chord{} = chord), do: build(chord)

  def new(fun) when is_function(fun, 0), do: build(fun.())

  def new({mod, fun, args}) when is_atom(mod) and is_atom(fun) and is_list(args) do
    mod |> apply(fun, args) |> build()
  end

  def new(name) when is_atom(name) do
    Chord |> apply(name, []) |> build()
  rescue
    UndefinedFunctionError -> {:error, "chord name provided can't be found in built-in chords: #{inspect(name)}"}
  end

  @doc """
  Returns an empty chord builder.

  The returned struct has no voicings and no pending steps.

  ## Examples

      iex> use Notex
      iex> Chord.base()
      %Notex.Chord{voicings: [], steps: []}

  """
  @spec base() :: t()
  def base do
    %Chord{
      voicings: [],
      steps: []
    }
  end

  defp append_step(chord, name, step) when is_atom(name) do
    %{chord | steps: [{name, step} | chord.steps]}
  end

  @doc """
  Executes all pending steps and returns a built chord.

  Steps run in insertion order. If a step returns an error tuple,
  building halts and returns an error prefixed with the failing step name.

  ## Examples

      iex> use Notex
      iex> chord_shape =
      ...>   Chord.base()
      ...>   |> Chord.put_intervals(:add_triad, [:one, :three, :five])
      iex> {:ok, chord} = Chord.build(chord_shape)
      iex> chord.voicings
      [five: [0], three: [0], one: [0]]

  """
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

  @doc group: "Chord shape transform API"
  @doc """
  Adds one or more intervals to a chord builder under a step name.

  `name` may be an atom or binary. Binaries are converted to atoms.
  `intervals` may be a single interval or a list of intervals.
  `voicing` is the list of octave offsets for each interval and defaults to `[0]`.

  This function records a step; it does not mutate voicings immediately.
  Call `build/1` to apply the step.

  ## Examples

      iex> use Notex
      iex> {:ok, chord} =
      ...>   Chord.base()
      ...>   |> Chord.put_intervals(:add_triad, [:one, :three, :five])
      ...>   |> Chord.build()
      iex> chord.voicings
      [five: [0], three: [0], one: [0]]

      iex> {:ok, chord} =
      ...>   Chord.base()
      ...>   |> Chord.put_intervals("add_root", :one, [-1, 0, 1])
      ...>   |> Chord.build()
      iex> chord.voicings
      [one: [-1, 0, 1]]

  """
  @spec put_intervals(t(), step_name() | binary(), [Types.interval_id()] | Types.interval_id(), [octave_offset()]) ::
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

  @doc group: "Chord shape transform API"
  @doc """
  Removes one or more intervals from a chord builder under a step name.

  `name` may be an atom or binary. `intervals` may be a single interval
  or a list of intervals.

  This function records a step; it does not mutate voicings immediately.
  Call `build/1` to apply the step.

  ## Examples

      iex> use Notex
      iex> {:ok, chord} =
      ...>   Chord.base()
      ...>   |> Chord.put_intervals(:add_triad, [:one, :three, :five])
      ...>   |> Chord.drop_intervals(:remove_third, :three)
      ...>   |> Chord.build()
      iex> chord.voicings
      [five: [0], one: [0]]

  """
  @spec drop_intervals(t(), step_name() | binary(), [Types.interval_id()] | Types.interval_id()) :: t()
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
          Types.interval_id(),
          (existing :: [octave_offset()] -> new :: [octave_offset()])
        ) ::
          t()
  @doc group: "Chord shape transform API"
  @doc """
  Updates the voicing list for an existing interval under a step name.

  The callback receives the interval's current octave-offset list and must
  return the new list.

  This function records a step; it does not mutate voicings immediately.
  Call `build/1` to apply the step.

  If the target interval does not exist when the step executes,
  `build/1` returns an error for that step.

  ## Examples

      iex> use Notex
      iex> {:ok, chord} =
      ...>   Chord.base()
      ...>   |> Chord.put_intervals(:add_root, :one, [0])
      ...>   |> Chord.update_voicing(:spread_root, :one, fn existing -> [-1 | existing] end)
      ...>   |> Chord.build()
      iex> chord.voicings
      [one: [-1, 0]]

  """

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

  The chord is built via `build/1` before note derivation. Each interval and
  octave offset is converted into a semitone target from `base_note`, then
  transposed with `Notex.Note.transpose/2`.

  The resulting notes are sorted by absolute pitch before being returned.

  Returns `{:ok, notes}` on success, or `{:error, reason}` when building or
  transposition fails.

  ## Examples

      iex> use Notex
      iex> chord = Chord.put_intervals(Chord.base(), :add_triad, [:one, :three, :five])
      iex> Chord.notes(chord, ~n[C4])
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

  @spec major() :: t()
  @doc group: "Builtin Chords"
  @doc "Returns a major triad chord shape (1 - 3 - 5)."
  def major do
    put_intervals(base(), :add_major_triad, [:one, :three, :five])
  end

  @spec minor() :: t()
  @doc group: "Builtin Chords"
  @doc "Returns a minor triad chord shape (1 - b3 - 5)."
  def minor do
    put_intervals(base(), :add_minor_triad, [:one, :flat_three, :five])
  end

  @spec diminished() :: t()
  @doc group: "Builtin Chords"
  @doc "Returns a diminished triad chord shape (1 - b3 - b5)."
  def diminished do
    minor()
    |> drop_intervals(:drop_five, :five)
    |> put_intervals(:add_flat_five, :flat_five)
  end

  @spec augmented() :: t()
  @doc group: "Builtin Chords"
  @doc "Returns an augmented triad chord shape (1 - 3 - #5)."
  def augmented do
    major()
    |> drop_intervals(:drop_five, :five)
    |> put_intervals(:add_sharp_five, :sharp_five)
  end

  @spec major7() :: t()
  @doc group: "Builtin Chords"
  @doc "Returns a major seventh chord shape (1 - 3 - 5 - 7)."
  def major7 do
    put_intervals(major(), :add_seventh, :seven)
  end

  @spec minor7() :: t()
  @doc group: "Builtin Chords"
  @doc "Returns a minor seventh chord shape (1 - b3 - 5 - b7)."
  def minor7 do
    put_intervals(minor(), :add_seventh, :flat_seven)
  end

  @spec dominant7() :: t()
  @doc group: "Builtin Chords"
  @doc "Returns a dominant seventh chord shape (1 - 3 - 5 - b7)."
  def dominant7 do
    put_intervals(major(), :add_seventh, :flat_seven)
  end

  @spec diminished7() :: t()
  @doc group: "Builtin Chords"
  @doc "Returns a diminished seventh chord shape (1 - b3 - b5 - 6)."
  def diminished7 do
    put_intervals(diminished(), :add_seventh, :six)
  end

  @spec half_diminished7() :: t()
  @doc group: "Builtin Chords"
  @doc "Returns a half-diminished seventh chord shape (1 - b3 - b5 - b7)."
  def half_diminished7 do
    put_intervals(diminished(), :add_seventh, :flat_seven)
  end

  @spec minor_major7() :: t()
  @doc group: "Builtin Chords"
  @doc "Returns a minor-major seventh chord shape (1 - b3 - 5 - 7)."
  def minor_major7 do
    put_intervals(minor(), :add_seventh, :seven)
  end

  @spec augmented7() :: t()
  @doc group: "Builtin Chords"
  @doc "Returns an augmented seventh chord shape (1 - 3 - #5 - b7)."
  def augmented7 do
    put_intervals(augmented(), :add_seventh, :flat_seven)
  end

  @spec major6() :: t()
  @doc group: "Builtin Chords"
  @doc "Returns a major sixth chord shape (1 - 3 - 5 - 6)."
  def major6 do
    put_intervals(major(), :add_sixth, :six)
  end

  @spec minor6() :: t()
  @doc group: "Builtin Chords"
  @doc "Returns a minor sixth chord shape (1 - b3 - 5 - 6)."
  def minor6 do
    put_intervals(minor(), :add_sixth, :six)
  end

  @spec sus2(t()) :: t()
  @doc group: "Builtin Chord transformations"
  @doc "Replaces the third with a major second."
  def sus2(%Chord{} = chord) do
    chord
    |> drop_intervals(:drop_three, :three)
    |> put_intervals(:add_two, :two)
  end

  @spec sus4(t()) :: t()
  @doc group: "Builtin Chord transformations"
  @doc "Replaces the third with a perfect fourth."
  def sus4(%Chord{} = chord) do
    chord
    |> drop_intervals(:drop_three, :three)
    |> put_intervals(:add_four, :four)
  end

  @spec power(t()) :: t()
  @doc group: "Builtin Chord transformations"
  @doc "Drops both the major and minor third, leaving root and fifth."
  def power(%Chord{} = chord) do
    chord
    |> drop_intervals(:drop_three, :three)
    |> drop_intervals(:drop_flat_three, :flat_three)
  end

  @spec add9(t()) :: t()
  @doc group: "Builtin Chord transformations"
  @doc "Adds a ninth (second, one octave up)."
  def add9(%Chord{} = chord) do
    put_intervals(chord, :add_ninth, :two, [1])
  end

  @spec add4(t()) :: t()
  @doc group: "Builtin Chord transformations"
  @doc "Adds a perfect fourth."
  def add4(%Chord{} = chord) do
    put_intervals(chord, :add_fourth, :four)
  end

  @spec add11(t()) :: t()
  @doc group: "Builtin Chord transformations"
  @doc "Adds an eleventh (fourth, one octave up)."
  def add11(%Chord{} = chord) do
    put_intervals(chord, :add_eleventh, :four, [1])
  end

  @spec add13(t()) :: t()
  @doc group: "Builtin Chord transformations"
  @doc "Adds a thirteenth (sixth, one octave up)."
  def add13(%Chord{} = chord) do
    put_intervals(chord, :add_thirteenth, :six, [1])
  end
end
