defmodule Mix.Tasks.Dicom.Scp do
  @moduledoc """
  Run a standalone C-STORE SCP service class provider (SCP).

  The task takes following arguments:

  * `--port <PORT>`: Port to listen on for incoming DICOM connections
  * `--print`: If set, received data sets are printed to standard out.
  * `--save <BASE_PATH>`: If set, received data sets are saved under base path.

  ## Examples

      mix dicom.scp --port 4242 --print --save ./scp_incoming
  """
  alias Dicom.DataSet
  alias Dicom.BinaryFormat
  use Mix.Task

  defp cstore_event_handler(print, save_path) do
    handler = fn %{dataset: ds} ->
      if print do
        IO.puts(ds)
      end

      if not is_nil(save_path) do
        study_uid = DataSet.value_for!(ds, :StudyInstanceUID)
        series_uid = DataSet.value_for!(ds, :SeriesInstanceUID)
        instance_uid = DataSet.value_for!(ds, :SOPInstanceUID)
        folder = Path.join([save_path, study_uid, series_uid])
        File.mkdir_p!(folder)
        target = Path.join(folder, "#{instance_uid}.dcm")
        data = BinaryFormat.to_file_data(ds)
        File.write!(target, data)
      end
    end

    handler
  end

  def run(argv) do
    {args, _rest} =
      OptionParser.parse!(argv, strict: [port: :integer, print: :boolean, save: :string])

    port = Keyword.get(args, :port, 8104)
    print = Keyword.get(args, :print, false)
    save_path = Keyword.get(args, :save, nil)
    handler = cstore_event_handler(print, save_path)

    {:ok, _pid} =
      DicomNet.Endpoint.start_link(port: port, event_handlers: [cstore: handler])

    keep_alive()
  end

  defp keep_alive() do
    Process.sleep(1000)
    keep_alive()
  end
end
