---
applyTo: "*.exs;*.ex"
---

To maintain code quality and reduce the backlog of potential issues, it is
standard practice to compile Elixir code with the `--warnings-as-errors` flag.

This can be done by running the following command:

`mix compile --warnings-as-errors`

This ensures that all warnings are treated as errors, forcing them to be
addressed before the code can be committed.
