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
* Receive C-ECHO, C-FIND and C-STORE network requests ([DICOM Part 3.7](https://dicom.nema.org/medical/dicom/current/output/chtml/part07/PS3.7.html))

## SCP Handlers

At the moment of configuring SCP services, the final developer must define functions called `event_handlers` which will take
care of the response to the SCU, based on the data received.  

At the moment of writing this readme, there are these handlers:  

**association_validator**  
> Allows/Rejects incomming connections.   

**cfind**  
> Receives incoming C-FIND requests and returns a Stream containing matches.  

**cstore**  
> Receives incoming C-STORE requests. The handler have access to the incoming dicom file and must take care of saving to filesystem, database, etc. 


## Examples

## Dicom parsing and writing

The following examples shows how to parse and access/write data from/to dicom files.  

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

## Dicom SCP

The following examples show how to create Dicom SCP services and their handlers.  

### Association Validation

This example allows incoming requests pointing to `TEST` AETitle, all other AETitles are rejected.  

To test an _accepting association_ you could run echoscu (from dcmtk) this way:  

```
echoscu -d -aec TEST 127.0.0.1 4242
```

To test an _rejecting association_ you could run echoscu (from dcmtk) this way:  

```
echoscu -d -aec OTHERAET 127.0.0.1 4242
```

```elixir
defmodule AssociationExample do
  use Application

  def start(_type, _args) do
    {:ok, endpoint_pid} = GenServer.start_link(
      DicomNet.Endpoint, 
      port: 4242,
      event_handlers: [
        association_validator: &association_handler/1,
      ]
    )

    loop()
    {:ok, endpoint_pid}
  end

  # Whithout this the server won't keep running
  defp loop() do
    loop()
  end

  defp association_handler(association_data) do
    case association_data.called_ae_title do
      "TEST" ->
        :accept
      _ ->
        {:reject, :dicom_ul_service_user, :called_ae_title_not_recognized}
    end
  end
end
```

### Receive C-STORE requests via network

```elixir
event_handlers = [
  cstore: &IO.inspect(&1, label: "C-Store")
]
{:ok, endpoint_pid} = GenServer.start_link(DicomNet.Endpoint, port: 4242, event_handlers: event_handlers)

# send data set, e.g. with DCMTK: storescu localhost 4242 dataset.dcm
```
