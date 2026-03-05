defmodule Notex.Types do
  @moduledoc """
  Shared public types for Notex APIs.

  These types are intended to be referenced from public specs and callbacks
  across modules such as `Notex.ScaleType` and `Notex.Chord`.
  """

  @typedoc """
  Canonical interval identifier used by scale and chord APIs.
  """
  @type interval_id() ::
          :one
          | :sharp_one
          | :flat_two
          | :two
          | :sharp_two
          | :flat_three
          | :three
          | :four
          | :sharp_four
          | :flat_five
          | :five
          | :sharp_five
          | :flat_six
          | :six
          | :sharp_six
          | :flat_seven
          | :seven
end
