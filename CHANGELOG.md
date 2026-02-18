# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/).

## [0.1.1] - 2026-02-18

### A new beginning!

- `Notex.Note` — create, parse, compare, and transpose musical notes with the `~n` sigil.
- `Notex.Scale` — build scale note lists from a tonic note and a scale type.
- `Notex.ScaleType` — behaviour for defining custom scale types.
- Built-in scale types: `Notex.ScaleType.Major` and `Notex.ScaleType.Minor`.
- Enharmonic normalization (flats to sharps, `B#` → `C`, `Cb` → `B`, etc.).
