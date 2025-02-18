defmodule DicomNet.EndpointIntegrationTest do
  use ExUnit.Case
  @port 54321

  @test_files Path.wildcard("#{__DIR__}/../test_files/**/*")
              |> Enum.filter(fn path ->
                case File.open(path) do
                  {:ok, file} ->
                    header = IO.binread(file, 132) |> String.slice(128, 132)
                    File.close(file)
                    header == "DICM"

                  _ ->
                    false
                end
              end)
              |> Enum.filter(&String.contains?(&1, ["MR_small.dcm"]))

  test "handles C-STORE requests" do
    self_pid = self()

    {:ok, endpoint_pid} =
      GenServer.start_link(DicomNet.Endpoint,
        port: @port,
        event_handlers: [cstore: fn evt -> send(self_pid, {:cstore_received, evt}) end]
      )

    @test_files
    |> Enum.each(fn file ->
      System.cmd("storescu", ["localhost", to_string(@port), file])
    end)

    assert_receive {:cstore_received, %{dataset: _}}
  end

  defp get_responses(dataset) do
    # Rename tags with atoms
    fields =
      Enum.map(dataset, fn {k, v} ->
        group = v.group_number
        element = v.element_number
        values = v.values

        case {group, element} do
          {0x0008, 0x0050} -> {:AccessionNumber, values}
          {0x0010, 0x0010} -> {:PatientName, values}
          {0x0010, 0x0020} -> {:PatientID, values}
          _ -> {:Ignore, nil}
        end
      end)

    # sample study list
    studies = [
      [PatientName: "Carmack^John", PatientID: "1", AccessionNumber: "A001"],
      [PatientName: "Kernighan^Brian", PatientID: "2", AccessionNumber: "A002"],
      [PatientName: "Torvalds^Linus", PatientID: "3", AccessionNumber: "A003"],
      [PatientName: "Van Rossum^Guido", PatientID: "4", AccessionNumber: "A004"],
      [PatientName: "Valim^José", PatientID: "5", AccessionNumber: "A005"]
    ]

    # Return the list excluding those fields not present in fields list.
    Enum.map(studies, fn study ->
      Keyword.take(study, Keyword.keys(fields))
      |> Dicom.DataSet.from_keyword_list()
    end)
  end

  # test "C-FIND" do
  #  {:ok, endpoint_pid} = GenServer.start_link(DicomNet.Endpoint, port: @port)
  #  DicomNet.Endpoint.register_listener(endpoint_pid, self())
  # 	DicomNet.Endpoint.register_cfind_getresponses(endpoint_pid, &get_responses/1)

  #  # give a second to start listening
  #  :timer.sleep(1000)

  #  {res, 0} = System.cmd("findscu", ["-W", "-k", "0008,0052=STUDY", "-k", "0008,0050", "-k", "0010,0010", "127.0.0.1", to_string(@port)],
  #    stderr_to_stdout: true)

  #  IO.inspect(res)

  #  assert_receive {:dicom, %{operation: :cstore, dataset: _ds}}
  # end
end
