defmodule Dicom.DataSetTest do
  use ExUnit.Case
  alias Dicom.DataSet

  doctest Dicom.DataSet

  test "create and access data set" do
    ds =
      DataSet.from_keyword_list(
        SOPInstanceUID: "1.2.3",
        PatientID: "ABC123",
        ImageType: ["Test1", "Test2", "Test3"],
        OriginalAttributesSequence: [
          DataSet.from_keyword_list(
            StudyInstanceUID: "1.2.3",
            SeriesInstanceUID: "1.2.3.1",
            PrivateInformation: <<1, 2, 3>>
          ),
          DataSet.from_keyword_list(
            StudyInstanceUID: "3.4.5",
            ModifiedAttributesSequence: [
              DataSet.from_keyword_list(SOPInstanceUID: "1.2.3.4.1"),
              DataSet.from_keyword_list(SOPInstanceUID: "1.23.2.4")
            ]
          )
        ]
      )

    # count
    assert Enum.count(ds) == 4

    # access by keyword
    assert DataSet.value_for!(ds, :PatientID) == "ABC123"
    # access by tuple
    assert DataSet.value_for!(ds, {0x0010, 0x0020}) == "ABC123"
    # access by full tag
    assert DataSet.value_for!(ds, 0x00100020) == "ABC123"

    assert DataSet.value_for!(ds, :ImageType, 2) == "Test3"

    assert_raise KeyError, fn -> DataSet.value_for!(ds, :StudyID) end
  end
end
