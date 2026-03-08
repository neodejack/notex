defmodule Notex.Chord do
  @moduledoc false
  alias __MODULE__
  alias Notex.Constant
  alias Notex.Note

  @type chord_step() :: (t() -> {:ok, t()} | {:error, binary()})

  @type octave_offset() :: integer()

  @type t() :: %Chord{
          voicings: [{Constant.interval_id(), [octave_offset()]}],
          steps: [chord_step()]
        }

  @enforce_keys [:voicings, :steps]
  defstruct [:voicings, :steps]

  def new do
    %Chord{
      voicings: [],
      steps: []
    }
  end

  @spec append_steps(
          t(),
          [chord_step()]
        ) :: t()
  def append_steps(chord, steps) do
    %{
      chord
      | steps: chord.steps ++ steps
    }
  end

  @spec build(t()) :: {:ok, t()} | {:error, binary()}
  def build(%Chord{steps: steps}) do
    Enum.reduce_while(steps, {:ok, new()}, fn step, {:ok, chord_acc} ->
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

  @spec add_interval(t(), Constant.interval_id()) :: t()
  def add_interval(%Chord{} = chord, interval) do
    append_steps(chord, [&add_interval_step(&1, interval)])
  end

  defp add_interval_step(%Chord{voicings: voicings} = chord, interval) do
    if Keyword.has_key?(voicings, interval) do
      chord
    else
      %{chord | voicings: voicings ++ [{interval, [0]}]}
    end
  end

  @spec omit_interval(t(), Constant.interval_id()) :: t()
  def omit_interval(%Chord{} = chord, interval) do
    append_steps(chord, [&omit_interval_step(&1, interval)])
  end

  defp omit_interval_step(%Chord{voicings: voicings} = chord, interval) do
    %{chord | voicings: Keyword.delete(voicings, interval)}
  end

  @spec set_voicing(t(), Constant.interval_id(), [octave_offset()]) :: t()
  def set_voicing(%Chord{} = chord, interval, voicing) do
    append_steps(chord, [&set_voicing_step(&1, interval, voicing)])
  end

  defp set_voicing_step(%Chord{voicings: voicings} = chord, interval, voicing) do
    if Keyword.has_key?(voicings, interval) do
      {:ok, %{chord | voicings: Keyword.put(voicings, interval, voicing)}}
    else
      {:error, "interval #{inspect(interval)} does not exist in chord voicings"}
    end
  end

  # @spec notes(t()) :: {:ok, [Note.t()]} | {:error, binary()}
  # def notes(%Chord{base_note: base_note, voicings: voicings}) do
  #   interval_semitones = Constant.interval_semitones()
  #
  #   semitones =
  #     for {interval, octave_offsets} <- voicings,
  #         octave_offset <- Enum.reverse(octave_offsets) do
  #       {Map.fetch!(interval_semitones, interval) + octave_semitones(octave_offset), {interval, octave_offset}}
  #     end
  #
  #   semitones
  #   |> Enum.reduce_while({:ok, []}, fn {semitone, {interval, octave_offset}}, {:ok, acc} ->
  #     case Note.transpose(base_note, semitone) do
  #       {:ok, note} ->
  #         {:cont, {:ok, [note | acc]}}
  #
  #       {:error, reason} ->
  #         error = "failed to build note for #{inspect({interval, octave_offset})}: #{reason}"
  #         {:halt, {:error, error}}
  #     end
  #   end)
  #   |> then(fn
  #     {:ok, built_notes} -> {:ok, Enum.reverse(built_notes)}
  #     {:error, reason} -> {:error, reason}
  #   end)
  # end
  #
  # defp octave_semitones(octave) when is_integer(octave) do
  #   octave * 12
  # end
end
