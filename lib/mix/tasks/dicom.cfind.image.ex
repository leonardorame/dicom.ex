defmodule Mix.Tasks.Dicom.Cfind.Image do
  @moduledoc """
  Perform an Image level C-FIND for the given Study and Series Instance UIDs.

  Usage:

      mix dicom.cfind.image --study STUDY_UID --series SERIES_UID [--host HOST] [--port PORT] \
        [--called AE] [--calling AE]

  Defaults are host `192.168.100.104`, port `10444`, called AE `iovpcFIR`, and calling AE `SCPAET`.
  """
  use Mix.Task

  alias Dicom.DataElement
  alias Dicom.DataSet

  @shortdoc "Run an Image level C-FIND and return metadata"

  @study_root_cfind "1.2.840.10008.5.1.4.1.2.2.1"

  @impl Mix.Task
  def run(args) do
    {opts, _rest, _invalid} =
      OptionParser.parse(args,
        switches: [
          host: :string,
          port: :integer,
          called: :string,
          calling: :string,
          study: :string,
          series: :string
        ]
      )

    connection =
      %{
        host: opts[:host] || "192.168.100.104",
        port: opts[:port] || 10444,
        called: opts[:called] || "iovpcFIR",
        calling: opts[:calling] || "SCPAET"
      }

    study_uid = fetch_required!(opts, :study, "--study option is required")
    series_uid = fetch_required!(opts, :series, "--series option is required")

    key = {__MODULE__, :connection}
    previous = Process.get(key)
    Process.put(key, connection)

    try do
      images = series_query(study_uid, series_uid)
      IO.inspect(images, label: "C-FIND (image level)")
    rescue
      error -> Mix.shell().error("C-FIND failed: #{inspect(error)}")
    after
      case previous do
        nil -> Process.delete(key)
        _ -> Process.put(key, previous)
      end
    end
  end

  defp fetch_required!(opts, key, message) do
    case opts[key] do
      nil -> raise ArgumentError, message
      value -> value
    end
  end

  defp series_query(study_instance_uid, series_instance_uid) do
    %{host: host, port: port, called: called, calling: calling} = current_connection()

    identifier =
      DataSet.from_keyword_list(
        QueryRetrieveLevel: "IMAGE",
        StudyInstanceUID: study_instance_uid,
        SeriesInstanceUID: series_instance_uid,
        SOPInstanceUID: nil,
        InstanceNumber: nil,
        Rows: nil,
        Columns: nil,
        NumberOfFrames: nil,
        ImageLaterality: nil
      )

    case DicomNet.SCU.cfind(host, port, called, calling, @study_root_cfind, identifier) do
      {:ok, datasets} -> Enum.map(datasets, &image_map/1)
      {:error, reason} -> raise "C-FIND image failed: #{inspect(reason)}"
    end
  end

  defp current_connection do
    key = {__MODULE__, :connection}

    case Process.get(key) do
      %{host: _host, port: _port, called: _called, calling: _calling} = conn -> conn
      _ -> %{host: "192.168.100.104", port: 10444, called: "iovpcFIR", calling: "SCPAET"}
    end
  end

  defp image_map(image_ds) do
    %{
      instancenumber:
        image_ds
        |> dataset_value(:InstanceNumber)
        |> maybe_integer(),
      columns:
        image_ds
        |> dataset_value(:Columns)
        |> maybe_integer(),
      rows:
        image_ds
        |> dataset_value(:Rows)
        |> maybe_integer(),
      numberofframes:
        image_ds
        |> dataset_value(:NumberOfFrames)
        |> normalize_frames(),
      imagelaterality: dataset_value(image_ds, :ImageLaterality)
    }
  end

  defp dataset_value(ds, keyword) do
    case DataSet.fetch(ds, keyword) do
      {:ok, de} ->
        case DataElement.value(de) do
          nil -> nil
          value -> normalize_value(value)
        end

      {:error, _} -> nil
    end
  end

  defp normalize_value(value) when is_binary(value), do: String.trim(value)
  defp normalize_value(value), do: value

  defp maybe_integer(nil), do: nil
  defp maybe_integer(value) when is_integer(value), do: value

  defp maybe_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp maybe_integer(value), do: value

  defp normalize_frames(nil), do: nil
  defp normalize_frames(value) when value in ["", "None"], do: nil

  defp normalize_frames(value) when is_binary(value) do
    case maybe_integer(value) do
      nil -> value
      frames -> frames
    end
  end

  defp normalize_frames(value), do: value
end
