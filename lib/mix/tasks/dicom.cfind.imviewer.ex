defmodule Mix.Tasks.Dicom.Cfind.Imviewer do
  @moduledoc """
  Perform a Study Root C-FIND for a given accession number and enrich the
  response with Series level C-FIND data in a single map structure.

  The task accepts the following options:

      mix dicom.cfind.imviewer --accession ACCESSION [--host HOST] [--port PORT] \
        [--called AE] [--calling AE]

  Defaults are host `192.168.100.104`, port `10444`, called AE `iovpcFIR`, and calling AE `SCPAET`.
  """
  use Mix.Task

  alias Dicom.DataElement
  alias Dicom.DataSet

  @shortdoc "Run a C-FIND (study + series) and merge the results"

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
          accession: :string
        ]
      )

    host = opts[:host] || "192.168.100.104"
    port = opts[:port] || 10444
    called = opts[:called] || "iovpcFIR"
    calling = opts[:calling] || "SCPAET"

    accession =
      case opts[:accession] do
        nil -> raise ArgumentError, "--accession option is required"
        value -> value
      end

    with {:ok, study_datasets} <- fetch_studies(host, port, called, calling, accession) do
      results =
        Enum.map(study_datasets, fn study_ds ->
          study_uid = dataset_value(study_ds, :StudyInstanceUID)

          series =
            case fetch_series(host, port, called, calling, study_uid) do
              {:ok, series_datasets} -> Enum.map(series_datasets, &series_map/1)
              {:error, reason} ->
                Mix.shell().error("Failed to fetch series for #{study_uid}: #{inspect(reason)}")
                []
            end

          study_map(study_ds, series)
        end)

      IO.inspect(results, label: "C-FIND (study + series)")
    else
      {:error, reason} -> Mix.shell().error("C-FIND failed: #{inspect(reason)}")
    end
  end

  defp fetch_studies(host, port, called, calling, accession) do
    identifier =
      DataSet.from_keyword_list(
        QueryRetrieveLevel: "STUDY",
        AccessionNumber: accession,
        StudyInstanceUID: "",
        StudyDate: "",
        StudyTime: "",
        PatientName: "",
        PatientID: "",
        StudyDescription: "",
        ModalitiesInStudy: ""
      )

    DicomNet.SCU.cfind(host, port, called, calling, @study_root_cfind, identifier)
  end

  defp fetch_series(_host, _port, _called, _calling, nil), do: {:ok, []}

  defp fetch_series(host, port, called, calling, study_instance_uid) do
    identifier =
      DataSet.from_keyword_list(
        QueryRetrieveLevel: "SERIES",
        StudyInstanceUID: study_instance_uid,
        SeriesInstanceUID: "",
        SeriesNumber: "",
        Modality: "",
        SeriesDescription: "",
        NumberOfSeriesRelatedInstances: ""
      )

    DicomNet.SCU.cfind(host, port, called, calling, @study_root_cfind, identifier)
  end

  defp study_map(study_ds, series) do
    series_image_count =
      series
      |> Enum.map(&Map.get(&1, :image_count, 0))
      |> Enum.reduce(0, fn
        nil, acc -> acc
        value, acc -> acc + value
      end)

    %{
      "study_instance_uid" => dataset_value(study_ds, :StudyInstanceUID),
      "accession_number" => dataset_value(study_ds, :AccessionNumber),
      "study_description" => dataset_value(study_ds, :StudyDescription),
      "modality" => dataset_value(study_ds, :ModalitiesInStudy) || dataset_value(study_ds, :Modality),
      "study_date" => dataset_value(study_ds, :StudyDate),
      "study_time" => dataset_value(study_ds, :StudyTime),
      "patient_name" => dataset_value(study_ds, :PatientName),
      "patient_id" => dataset_value(study_ds, :PatientID),
      "image_count" => series_image_count,
      "series" => Enum.map(series, &stringify_series_map/1)
    }
  end

  defp series_map(series_ds) do
    %{
      series_instance_uid: dataset_value(series_ds, :SeriesInstanceUID),
      study_instance_uid: dataset_value(series_ds, :StudyInstanceUID),
      series_number: maybe_integer(dataset_value(series_ds, :SeriesNumber)),
      modality: dataset_value(series_ds, :Modality),
      description: dataset_value(series_ds, :SeriesDescription),
      image_count:
        dataset_value(series_ds, :NumberOfSeriesRelatedInstances)
        |> maybe_integer()
    }
  end

  defp stringify_series_map(series) do
    %{
      "series_instance_uid" => series.series_instance_uid,
      "study_instance_uid" => series.study_instance_uid,
      "series_number" => series.series_number,
      "modality" => series.modality,
      "description" => series.description,
      "image_count" => series.image_count
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

  defp normalize_value(value) when is_binary(value) do
    String.trim(value)
  end

  defp normalize_value(value), do: value

  defp maybe_integer(nil), do: nil
  defp maybe_integer(value) when is_integer(value), do: value

  defp maybe_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp maybe_integer(value) do
    value
  end
end
