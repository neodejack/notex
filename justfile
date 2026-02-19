list:
  @just --list --list-heading $'Hey Mr.Scott whatcha gonna do\n' --list-prefix '~> '

ci:
    mix format --check-formatted
    mix compile --warnings-as-errors
    mix credo --strict --ignore-checks Design.Tag
    MIX_ENV=test mix test
    mix dialyzer

docs:
  mix docs
  open doc/index.html

