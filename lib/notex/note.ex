defmodule Notex.Note do
  @moduledoc """
  Represents a _[Scientific pitch notation](https://en.wikipedia.org/wiki/Scientific_pitch_notation)_ with a name and octave.

  A `Notex.Note` is a struct with two fields:

    * `:note_name` — the canonical note name (e.g. `"C"`, `"F#"`)
    * `:octave` — the octave number (0–9)

  ## Creating Notes

  Use `new/2`, `parse/1`, or the `~n` sigil (available via `import Notex.Note`):

      iex> Notex.Note.new("C", 4)
      {:ok, ~n[C4]}

      iex> Notex.Note.parse("Ab3")
      {:ok, ~n[G#3]}

      iex> import Notex.Note
      iex> ~n[F#5]
      ~n[F#5]

  Notes implement `String.Chars` and `Inspect`, so they display as `"C4"` with
  `to_string/1` and as `~n[C4]` when inspected.
  """

  alias __MODULE__
  alias Notex.Constant

  @typedoc """
  A note struct with a `:note_name` and `:octave`.
  """
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

  @doc """
  Creates a new note from a `note_name` string and an `octave` integer.

  When creating notes, they are always converted to their canonical sharp form.
  Flats are automatically converted to their enharmonic sharp equivalents (e.g. `"Ab"` becomes `"G#"`),
  and boundary enharmonics are normalized
  (`"B#"` becomes `"C"` with octave + 1, `"Cb"` becomes `"B"` with octave - 1).


  Returns `{:ok, note}` on success or `{:error, reason}` if the note name
  or octave is invalid.

  ## Examples

      iex> Notex.Note.new("C", 4)
      {:ok, ~n[C4]}

      iex> Notex.Note.new("Ab", 3)
      {:ok, ~n[G#3]}

      iex> Notex.Note.new("B#", 3)
      {:ok, ~n[C4]}
  """
  @spec new(String.t(), integer()) :: {:ok, t()} | {:error, String.t()}
  def new(note_name, octave) when is_binary(note_name) and is_integer(octave) do
    build_note(note_name, octave)
  end

  @doc """
  Bang variant of `new/2`. Returns the note directly or raises `ArgumentError`.

  """
  @spec new!(String.t(), integer()) :: t()
  def new!(note_name, octave) when is_binary(note_name) and is_integer(octave) do
    case new(note_name, octave) do
      {:ok, note} -> note
      {:error, reason} -> raise ArgumentError, "Failed to create new note, reason:\n#{reason}"
    end
  end

  @doc """
  Returns `true` if two notes are structurally equal.

  ## Examples

      iex> import Notex.Note
      iex> equal?(~n[C4], ~n[C4])
      true
      iex> equal?(~n[C4], ~n[D4])
      false
      iex> equal?(~n[B#3], ~n[C4])
      true

  """
  @spec equal?(t(), t()) :: boolean()
  def equal?(%Note{} = note1, %Note{} = note2), do: note1 == note2

  @doc """
  Bang variant of `transpose/2`. Returns the transposed note directly or raises `ArgumentError`.

  """
  @spec transpose!(t(), integer()) :: t()
  def transpose!(%Note{} = note, semitones) when is_integer(semitones) do
    case transpose(note, semitones) do
      {:ok, new_note} -> new_note
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @doc """
  Transposes a note by the given number of `semitones`.

  Positive values transpose up, negative values transpose down. Octave boundaries
  are handled automatically.

  Returns `{:ok, note}` on success or `{:error, reason}` if the resulting note
  would be outside the valid octave range.

  ## Examples

      iex> transpose(~n[C4], 7)
      {:ok, ~n[G4]}
      iex> transpose(~n[B4], 1)
      {:ok, ~n[C5]}
      iex> transpose(~n[C4], -1)
      {:ok, ~n[B3]}

  """
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

  @doc """
  Sigil for creating notes inline.

  Import `Notex.Note` to use the `~n` sigil. The sigil parses a note string
  and raises on invalid input.

  ## Examples

      iex> import Notex.Note

      iex> ~n[C4]
      ~n[C4]

      iex> ~n[G#5]
      ~n[G#5]

  """
  def sigil_n(note, []), do: parse!(note)

  @doc """
  Bang variant of `parse/1`. Returns the note directly or raises `ArgumentError`.

  """
  @spec parse!(binary()) :: t()
  def parse!(note) do
    case parse(note) do
      {:ok, note} -> note
      {:error, reason} -> raise ArgumentError, "Failed to build note, reason:\n#{reason}"
    end
  end

  @doc """
  Parses a string representation of a note into a `t:Notex.Note.t/0` struct.

  Expects a 2- or 3-character string
  - character one: a letter (`A`–`G`)
  - (optional) character two: accidental (`#` or `b`)
  - character three: a single-digit octave (`0`–`9`).

  Flats are normalized to sharps, and lowercase letters are uppercased.

  Returns `{:ok, note}` on success or `{:error, reason}` on failure.

  ## Examples

      iex> Notex.Note.parse("C4")
      {:ok, ~n[C4]}

      iex> Notex.Note.parse("Ab3")
      {:ok, ~n[G#3]}

      iex> Notex.Note.parse("B#3")
      {:ok, ~n[C4]}

      iex> {:error, _reason} = Notex.Note.parse("H1")

  """
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

  @doc """
  Compares two notes by their absolute pitch.

  Returns `:gt`, `:lt`, or `:eq`.

  ## Examples

      iex> Notex.Note.compare(~n[D4], ~n[C4])
      :gt
      iex> Notex.Note.compare(~n[C4], ~n[C4])
      :eq
      iex> Notex.Note.compare(~n[C4], ~n[D4])
      :lt

  """
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
