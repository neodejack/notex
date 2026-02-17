defmodule Notex.Note do
  @moduledoc false
  alias __MODULE__
  alias Notex.Constant

  @type t :: %__MODULE__{note_name: String.t(), octave: integer()}

  @enforce_keys [:note_name, :octave]
  defstruct [:note_name, :octave]

  defimpl String.Chars, for: Note do
    def to_string(note) do
      "#{note.note_name}#{note.octave}"
    end
  end

  defimpl Inspect, for: Note do
    def inspect(note, _opts) do
      "~n[#{note.note_name}#{note.octave}]"
    end
  end

  @spec new(String.t(), integer()) :: {:ok, t()} | {:error, String.t()}
  def new(note_name, octave) when is_binary(note_name) and is_integer(octave) do
    build_note(note_name, octave)
  end

  @spec new!(String.t(), integer()) :: t()
  def new!(note_name, octave) when is_binary(note_name) and is_integer(octave) do
    case new(note_name, octave) do
      {:ok, note} -> note
      {:error, reason} -> raise ArgumentError, "Failed to create new note, reason:\n#{reason}"
    end
  end

  @spec equal?(t(), t()) :: boolean()
  def equal?(%Note{} = note1, %Note{} = note2), do: note1 == note2

  @spec transpose!(t(), integer()) :: t()
  def transpose!(%Note{} = note, semitones) when is_integer(semitones) do
    case transpose(note, semitones) do
      {:ok, new_note} -> new_note
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @spec transpose(t(), integer()) :: {:ok, t()} | {:error, String.t()}
  def transpose(%Note{note_name: note_name, octave: octave}, semitones) when is_integer(semitones) do
    scale = Constant.all_note_names()
    size = length(scale)
    pos = Enum.find_index(scale, &(&1 == note_name))
    total = pos + semitones

    new_note_name = Enum.at(scale, Integer.mod(total, size))
    new_octave = octave + Integer.floor_div(total, size)

    case new(new_note_name, new_octave) do
      {:ok, note} -> {:ok, note}
      {:error, reason} -> {:error, "Failed to create newly transoped note, reason:\n#{reason}"}
    end
  end

  def sigil_n(note, []), do: parse!(note)

  @spec parse!(binary()) :: t()
  def parse!(note) do
    case parse(note) do
      {:ok, note} -> note
      {:error, reason} -> raise ArgumentError, "Failed to build note, reason:\n#{reason}"
    end
  end

  @spec parse(binary()) :: {:ok, t()} | {:error, String.t()}
  def parse(note)

  def parse(<<note_name, octave>>), do: build_note(<<note_name>>, <<octave>>)

  def parse(<<note_name, accidental, octave>>), do: build_note(<<note_name, accidental>>, <<octave>>)

  def parse(note) when is_binary(note) do
    {:error,
     """
     Bad note shape 

     expect: 2 or 3 characters of string
     received: #{inspect(note)}
     """}
  end

  @spec compare(t(), t()) :: :gt | :lt | :eq
  def compare(%Note{} = note1, %Note{} = note2) do
    note1_abs = absolute_semitones(note1)
    note2_abs = absolute_semitones(note2)

    cond do
      note1_abs > note2_abs -> :gt
      note1_abs < note2_abs -> :lt
      true -> :eq
    end
  end

  defp absolute_semitones(%Note{} = note) do
    size = Constant.note_name_count()
    indexes = Constant.note_name_indexes()
    note_pos = Map.fetch!(indexes, note.note_name)

    note.octave * size + note_pos
  end

  defp build_note(note_name, octave) when is_binary(note_name) and is_binary(octave) do
    case Integer.parse(octave) do
      {octave_int, ""} -> build_note(note_name, octave_int)
      {_, _} -> {:error, invald_octave_error(octave)}
      :error -> {:error, invald_octave_error(octave)}
    end
  end

  defp build_note(note_name, octave) when is_binary(note_name) and is_integer(octave) do
    with {:ok, {parsed_note_name, octave_delta}} <- parse_name(note_name),
         {:ok, parsed_octave} <- parse_octave(octave + octave_delta) do
      {:ok,
       %Note{
         note_name: parsed_note_name,
         octave: parsed_octave
       }}
    end
  end

  defp invald_octave_error(octave) do
    valid_octaves = Enum.map_join(Constant.all_octaves(), ",", &Integer.to_string/1)

    """
    Invalid octave

    valid octaves: #{valid_octaves}
    received octave: #{inspect(octave)}
    """
  end

  defp invald_note_name_error(note_name) do
    """
    Invalid note_name

    valid note_names: #{Enum.intersperse(Constant.all_note_names(), ",")}
    received note_name: #{inspect(note_name)}
    """
  end

  defp valid_note_name?(note_name) when is_binary(note_name) do
    note_name in Constant.all_note_names()
  end

  defp valid_octave?(octave) when is_integer(octave) do
    octave in Constant.all_octaves()
  end

  defp parse_name(note_name) do
    {normalized_note_name, octave_delta} = normalize_note_name(note_name)

    if valid_note_name?(normalized_note_name) do
      {:ok, {normalized_note_name, octave_delta}}
    else
      {:error, invald_note_name_error(note_name)}
    end
  end

  defp parse_octave(octave) when is_integer(octave) do
    if valid_octave?(octave) do
      {:ok, octave}
    else
      {:error, invald_octave_error(octave)}
    end
  end

  defp normalize_note_name(<<letter>>) do
    {String.upcase(<<letter>>), 0}
  end

  defp normalize_note_name(<<letter, accidental>>) do
    note_name = String.upcase(<<letter>>) <> <<accidental>>

    cond do
      Map.has_key?(Constant.enharmonic_map(), note_name) ->
        Map.fetch!(Constant.enharmonic_map(), note_name)

      Map.has_key?(Constant.flat_to_sharp_map(), note_name) ->
        {Map.fetch!(Constant.flat_to_sharp_map(), note_name), 0}

      true ->
        {note_name, 0}
    end
  end

  defp normalize_note_name(invalid_note_name) do
    {invalid_note_name, 0}
  end
end
