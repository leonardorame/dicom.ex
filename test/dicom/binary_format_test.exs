defmodule Dicom.BinaryFormatTest do
  alias Dicom.DataSet
  alias Dicom.BinaryFormat

  use ExUnit.Case

  test "parses sequence fields" do
    # explicit length list
    data =
      :binary.decode_hex(
        "080032105351000040000000FEFF00E03800000008000001534808004354434F4555520008000201534806004" <>
          "2524F4B4552080004014C4F1200434154205343414E20434152444941515500"
      )

    {:ok, {de, <<>>}} =
      BinaryFormat.read_next_data_element(data, endianness: :little, explicit: true)

    assert length(de.values) == 1
    assert Enum.count(List.first(de.values)) == 3

    # implicit length list
    data =
      :binary.decode_hex(
        "0800401153510000FFFFFFFFFEFF00E0FFFFFFFF0800501155491A00312E322E3834302E31303030382E352E3" <>
          "12E342E312E312E32000800551155493800312E332E31322E322E313130372E352E312E342E35343032332E" <>
          "333030303030303430393330313333303338363837303030303135373400FEFF0DE000000000FEFFDDE000000000"
      )

    {:ok, {de, <<>>}} =
      BinaryFormat.read_next_data_element(data, endianness: :little, explicit: true)

    assert length(de.values) == 1
    assert Enum.count(List.first(de.values)) == 2

    # nested list
    # TODO replace with test data where nested sequene has actual content
    data =
      :binary.decode_hex(
        "400075025351000056000000FEFF00E04E000000400007004C4F1200436174207363616E20636172646961717" <>
          "5654000080053510000000000004000090053480C004131303030333230343934374000011053480C004131" <>
          "30303033323034393436"
      )

    {:ok, {de, <<>>}} =
      BinaryFormat.read_next_data_element(data, endianness: :little, explicit: true)

    assert length(de.values) == 1

    {_tag, nested_sequence} =
      de.values
      |> List.first()
      |> Enum.filter(fn {_tag, de} -> de.vr == :SQ end)
      |> List.first()

    assert length(nested_sequence.values) == 0

    # sequence with multiple itemsmix test cover.st
    data =
      :binary.decode_hex(
        "180011605351000018010000FEFF00E0840000001800126055530200010018001460555302000100180016605" <>
          "54C04000200000018001860554C04005200000018001A60554C0400E100000018001C60554C04001E020000" <>
          "18001E60554C040034020000180024605553020003001800266055530200030018002C60464408001AD07C5" <>
          "0C579983F18002E60464408001AD07C50C579983FFEFF00E084000000180012605553020001001800146055" <>
          "530200010018001660554C04000200000018001860554C04002402000018001A60554C0400E100000018001" <>
          "C60554C0400F003000018001E60554C04003402000018002460555302000300180026605553020003001800" <>
          "2C60464408001AD07C50C579983F18002E60464408001AD07C50C579983F"
      )

    {:ok, {de, <<>>}} =
      BinaryFormat.read_next_data_element(data, endianness: :little, explicit: true)

    assert length(de.values) == 2
    assert Enum.count(List.first(de.values)) == 11
    assert Enum.count(Enum.at(de.values, 1)) == 11
  end

  defp is_dicom_file(path) do
    case File.open(path) do
      {:ok, file} ->
        header = IO.binread(file, 132) |> String.slice(128, 132)
        File.close(file)
        header == "DICM"

      _ ->
        false
    end
  end

  test "read files" do
    test_files =
      Path.wildcard("#{__DIR__}/../test_files/**/*")
      |> Enum.filter(&is_dicom_file/1)

    failing_files =
      test_files
      |> Enum.filter(fn path ->
        case BinaryFormat.from_file(path) do
          {:ok, _ds} -> false
          {:error, _err} -> true
        end
      end)
      |> Enum.map(&Path.basename/1)
      |> Enum.into(MapSet.new())

    # invalid files or missing metadata is not supported right now
    expected_failing =
      MapSet.new([
        "MR_truncated.dcm",
        "emri_small_jpeg_2k_lossless_too_short.dcm",
        "image_dfl.dcm",
        "meta_missing_tsyntax.dcm",
        "no_meta_group_length.dcm",
        "rtplan_truncated.dcm"
      ])

    assert failing_files == expected_failing
  end

  test "file serialization" do
    ds =
      DataSet.from_keyword_list(
        SOPClassUID: "1.2",
        SOPInstanceUID: "1.2.3",
        OriginalAttributesSequence: [
          DataSet.from_keyword_list(StudyID: "STD1"),
          DataSet.from_keyword_list(StudyID: "STD2")
        ]
      )
      |> DataSet.with_transfer_syntax(:explicit_vr_little_endian)

    data = BinaryFormat.to_file_data(ds)

    File.write!("writetest.dcm", data)
  end
end
