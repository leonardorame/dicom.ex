defmodule Mix.Tasks.Dicom.DecodeLossless do
  @moduledoc """
  Open `test.dcm`, parse it and decode the JPEG Lossless pixel data.

  Each encapsulated frame is decoded and the number of bytes of the
  resulting pixel stream is printed.
  """
  use Mix.Task

  alias Dicom.DataSet
  alias Dicom.BinaryFormat

  @impl Mix.Task
  def run(_args) do
    ds = BinaryFormat.from_file!("test.dcm")
    frames = pixel_frames(ds)

    Enum.each(Enum.with_index(frames, 1), fn {frame, idx} ->
      decoded = BinaryFormat.decode_jpeg_lossless(frame)
      IO.puts("Frame #{idx}: #{byte_size(decoded)} bytes decoded")
    end)
  end

  defp pixel_frames(ds) do
    value = DataSet.value_for!(ds, :PixelData)

    cond do
      is_list(value) ->
        case value do
          [offset_table | frames] when is_binary(offset_table) -> frames
          frames -> frames
        end

      is_binary(value) ->
        [value]
    end
  end
end
