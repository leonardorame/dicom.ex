# Dicom.ex

Dicom.ex is a Elixir library implementing the [DICOM](https://www.dicomstandard.org/)
standard for data storage and network transfers.

**Attention:** This project is a personal project to
learn Elixir and DICOM internals. It should not be used
in production and absolutely not in clinical contexts.

## Features

* General methods to work with DICOM data sets and elements
* Read data sets from files encode according to [DICOM Part 3.10](https://dicom.nema.org/medical/dicom/current/output/chtml/part10/chapter_7.html)
* Supports VRs and tag dictionary as of DICOM version 2024d
* Receive C-STORE network requests ([DICOM Part 3.7](https://dicom.nema.org/medical/dicom/current/output/chtml/part07/PS3.7.html))

## Examples

### Create and access DICOM data set

```elixir
ds =
  Dicom.DataSet.from_keyword_list(
    SOPInstanceUID: "1.2.3",
    PatientID: "ABC123",
    ImageType: ["Test1", "Test2", "Test3"]
  )

assert Dicom.DataSet.value_for!(ds, :PatientID) == "ABC123"
assert Dicom.DataSet.value_for!(ds, :ImageType, 2) == "Test3"
```

### Read DICOM data set from file

```elixir
ds = Dicom.BinaryFormat.from_file!("test/test_files/test-ExplicitVRLittleEndian.dcm")
```

### Receive C-STORE requests via network

```elixir
{:ok, endpoint_pid} = GenServer.start_link(DicomNet.Endpoint, port: 4242)
DicomNet.Endpoint.register_listener(endpoint_pid, self())

# send data set, e.g. with DCMTK: storescu localhost 4242 dataset.dcm

receive do
  {:dicom, %{operation: :cstore, dataset: ds}} ->
    # do something with the data set
end
```
