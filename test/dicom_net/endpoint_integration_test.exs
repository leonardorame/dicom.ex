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
    {:ok, endpoint_pid} = GenServer.start_link(DicomNet.Endpoint, port: @port)
    DicomNet.Endpoint.register_listener(endpoint_pid, self())

    @test_files
    |> Enum.each(fn file ->
      System.cmd("storescu", ["localhost", to_string(@port), file])
    end)

    assert_received {:dicom, %{operation: :cstore, dataset: _ds}}
  end
end
