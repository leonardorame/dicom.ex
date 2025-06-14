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

    decoded_frames =
      Enum.map(Enum.with_index(frames, 1), fn {frame, idx} ->
        decoded = BinaryFormat.decode_jpeg_lossless(frame)
        IO.puts("Frame #{idx}: #{byte_size(decoded)} bytes decoded")
        decoded
      end)

    bits_allocated = DataSet.value_for!(ds, :BitsAllocated)
    vr = if bits_allocated <= 8, do: :OB, else: :OW

    pixel_data = Enum.reduce(decoded_frames, <<>>, fn frame, acc -> acc <> frame end)

    ds =
      ds
      |> DataSet.put(:PixelData, vr, [pixel_data])
      |> DataSet.with_transfer_syntax(:explicit_vr_little_endian)

    data = BinaryFormat.to_file_data(ds)
    File.write!("test_decoded.dcm", data)
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
