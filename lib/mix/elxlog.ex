defmodule Mix.Tasks.Elxlog do
  use Mix.Task

  def run(_) do
    Elxlog.repl()
  end
end
