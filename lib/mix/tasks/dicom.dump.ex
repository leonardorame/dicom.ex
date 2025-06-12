defmodule Mix.Tasks.Dicom.Dump do
  @moduledoc """
  Read and pretty print DICOM file.
  """
  use Mix.Task

  def run(args) do
    Enum.each(args, fn path ->
      IO.puts("# File: #{path}")

      case Dicom.BinaryFormat.from_file(path) do
        {:ok, ds} -> IO.puts(ds)
        {:error, reason} -> IO.puts("File cannot be read: #{reason}")
      end

      IO.puts("")
    end)
  end
end
