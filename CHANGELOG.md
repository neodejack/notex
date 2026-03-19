# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/).

## [0.1.2] - 2026-03-19

### Chords API is here

- Added `Notex.Chord` with a composable chord-shape pipeline: `base/0`, `put_intervals/3-4`, `drop_intervals/3`, `update_voicing/4`, `build/1`, and `notes/2`.
- Added built-in chord constructors and transforms, including triads/sevenths (`major`, `minor`, `dominant7`, etc.) and modifiers (`sus2`, `sus4`, `add9`, `add11`, `add13`, `power`).
- Added `Notex.Types` for shared public types and standardized interval APIs in `Notex.Constant` (`intervals/0`, `interval_semitones/0`, `interval_names/0`, `interval_ids/0`) plus the `is_interval/1` guard.
- Improved ergonomics of `use Notex` by importing `~n` and `is_interval/1`, and aliasing `Chord`, `Note`, and `Scale`.
- Updated scale type behaviour to use `intervals/0` and improved missing scale-type errors to show attempted resolutions.

## [0.1.1] - 2026-02-18

### A new beginning!

- `Notex.Note` — create, parse, compare, and transpose musical notes with the `~n` sigil.
- `Notex.Scale` — build scale note lists from a tonic note and a scale type.
- `Notex.ScaleType` — behaviour for defining custom scale types.
- Built-in scale types: `Notex.ScaleType.Major` and `Notex.ScaleType.Minor`.
- Enharmonic normalization (flats to sharps, `B#` → `C`, `Cb` → `B`, etc.).
