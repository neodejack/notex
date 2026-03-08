defmodule Notex.Chord do
  @moduledoc false
  alias __MODULE__
  alias Notex.Constant
  alias Notex.Note

  @type chord_step() :: (t() -> {:ok, t()} | {:error, binary()})

  @type octave_offset() :: integer()

  @type t() :: %Chord{
          base_note: Note.t(),
          voicings: [{Constant.interval_id(), [octave_offset()]}]
        }

  @enforce_keys [:base_note, :voicings, :steps, :current_steps]
  defstruct [:base_note, :voicings, :steps, :current_steps]

  @spec append_steps(
          t(),
          keyword(chord_step())
        ) :: t()
  def append_steps(chord, steps) do
    %{
      chord
      | steps: chord.steps ++ steps,
        current_steps: chord.current_steps ++ Keyword.keys(steps)
    }
  end

  @spec build_chord(t()) :: {:ok, t()} | {:error, binary()}
  def build_chord(chord) do
    # pattern-matches on current_steps.
    # If that list has entries, it takes the next step name, looks up the function from steps, runs it using run_step/2, and then recursively continues with the remaining current_steps.
  end

  defp run_step(step, state) when is_function(step, 1) do
    step.(state)
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
end
