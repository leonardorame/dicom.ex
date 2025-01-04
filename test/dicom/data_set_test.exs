defmodule Dicom.DataSetTest do
  use ExUnit.Case
  alias Dicom.DataSet

  test "create and access data set" do
    ds =
      DataSet.from_keyword_list(
        SOPInstanceUID: "1.2.3",
        PatientID: "ABC123",
        ImageType: ["Test1", "Test2", "Test3"]
      )

    assert DataSet.value_for!(ds, :PatientID) == "ABC123"
    assert DataSet.value_for!(ds, :ImageType, 2) == "Test3"
  end
end
