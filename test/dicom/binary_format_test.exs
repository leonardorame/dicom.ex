defmodule Dicom.BinaryFormatTest do
  alias Dicom.DataElement
  alias Dicom.DataSet
  alias Dicom.BinaryFormat
  use ExUnit.Case

  defp parse_test_sample(%{options: options, data: data}) do
    data = :binary.decode_hex(data)
    {:ok, {data_element, <<>>}} = BinaryFormat.read_next_data_element(data, options)
    data_element
  end

  defp assert_sample_parses_correctly(sample, expected) do
    actual = parse_test_sample(sample)

    # round float values to a fixed precision
    {actual, expected} =
      if expected.vr in [:FL, :FD] do
        {
          %DataElement{actual | values: actual.values |> Enum.map(&Float.round(&1, 5))},
          %DataElement{expected | values: expected.values |> Enum.map(&Float.round(&1, 5))}
        }
      else
        {actual, expected}
      end

    assert actual == expected
  end

  test "parses application entity title (AE) fields" do
    expected = %DataElement{
      group_number: 0x0008,
      element_number: 0x0055,
      vr: :AE,
      values: ["AETITLE"]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "080055004145080041455449544c4520"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "000800554145000841455449544c4520"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "080055000800000041455449544c4520"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses age string (AS) fields" do
    expected = %DataElement{
      group_number: 0x0010,
      element_number: 0x1010,
      vr: :AS,
      values: ["042Y"]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "100010104153040030343259"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "001010104153000430343259"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "100010100400000030343259"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses attribute tag (AT) fields" do
    expected = %DataElement{
      group_number: 0x0014,
      element_number: 0x0202,
      vr: :AT,
      values: [0x00020010]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "140002024154040002001000"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "001402024154000400020010"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "140002020400000002001000"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses code string (CS) fields" do
    expected = %DataElement{
      group_number: 0x0008,
      element_number: 0x0008,
      vr: :CS,
      values: ["CODESTRING"]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "0800080043530a00434f4445535452494e47"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "000800084353000a434f4445535452494e47"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "080008000a000000434f4445535452494e47"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses date (DA) fields" do
    expected = %DataElement{
      group_number: 0x0008,
      element_number: 0x0012,
      vr: :DA,
      values: ["20000101"]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "08001200444108003230303030313031"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "00080012444100083230303030313031"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "08001200080000003230303030313031"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses decimal string (DS) field" do
    expected = %DataElement{
      group_number: 0x0010,
      element_number: 0x1020,
      vr: :DS,
      values: ["1.93"]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "1000201044530400312e3933"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "0010102044530004312e3933"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "1000201004000000312e3933"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses date time (DT) fields" do
    expected = %DataElement{
      group_number: 0x0008,
      element_number: 0x0015,
      vr: :DT,
      values: ["20240102131415"]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "0800150044540e003230323430313032313331343135"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "000800154454000e3230323430313032313331343135"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "080015000e0000003230323430313032313331343135"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses float (FT) fields" do
    expected = %DataElement{
      group_number: 0x0018,
      element_number: 0x2046,
      vr: :FL,
      values: [1.234]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "18004620464c0400b6f39d3f"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "00182046464c00043f9df3b6"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "1800462004000000b6f39d3f"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses double (FD) fields" do
    expected = %DataElement{
      group_number: 0x0008,
      element_number: 0x1163,
      vr: :FD,
      values: [1.23456789, 9.012345678]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "08006311464410001bde8342cac0f33f8f83362c52062240"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "00081163464400103ff3c0ca4283de1b402206522c36838f"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "08006311100000001bde8342cac0f33f8f83362c52062240"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses integer string (IS) fields" do
    expected = %DataElement{
      group_number: 0x0008,
      element_number: 0x1160,
      vr: :IS,
      values: ["123"]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "080060114953040031323320"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "000811604953000431323320"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "080060110400000031323320"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses integer fields" do
    data = :binary.decode_hex("02000000554C0400BE000000")

    {:ok, {de, <<>>}} =
      BinaryFormat.read_next_data_element(data, endianness: :little, explicit: true)

    assert de == %Dicom.DataElement{
             group_number: 0x0002,
             element_number: 0x0000,
             vr: :UL,
             values: [190]
           }
  end

  test "parses uid fields" do
    data1 =
      :binary.decode_hex("0800160055491A00312E322E3834302E31303030382E352E312E342E312E312E3200")

    {:ok, {de, <<>>}} =
      BinaryFormat.read_next_data_element(data1, endianness: :little, explicit: true)

    assert de == %Dicom.DataElement{
             group_number: 0x0008,
             element_number: 0x0016,
             vr: :UI,
             values: ["1.2.840.10008.5.1.4.1.1.2"]
           }
  end

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
    assert map_size(List.first(de.values)) == 3

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
    assert map_size(List.first(de.values)) == 2

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

    nested_sequence =
      de.values
      |> List.first()
      |> Map.values()
      |> Enum.filter(fn de -> de.vr == :SQ end)
      |> List.first()

    assert length(nested_sequence.values) == 0

    # sequence with multiple items
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
    assert map_size(List.first(de.values)) == 11
    assert map_size(Enum.at(de.values, 1)) == 11
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

  # test "read files" do
  #   test_files =
  #     Path.wildcard("#{__DIR__}/../test_files/**/*")
  #     |> Enum.filter(&is_dicom_file/1)

  #   failing_files =
  #     test_files
  #     |> Enum.filter(fn path ->
  #       case BinaryFormat.from_file(path) do
  #         {:ok, _ds} -> false
  #         {:error, _err} -> true
  #       end
  #     end)
  #     |> Enum.map(&Path.basename/1)
  #     |> Enum.into(MapSet.new())

  #   # TODO what is the problem with the private SQs?
  #   # invalid files or missing metadata is not supported right now
  #   expected_failing =
  #     MapSet.new([
  #       "MR_truncated.dcm",
  #       "emri_small_jpeg_2k_lossless_too_short.dcm",
  #       "image_dfl.dcm",
  #       "meta_missing_tsyntax.dcm",
  #       "nested_priv_SQ.dcm",
  #       "no_meta_group_length.dcm",
  #       "priv_SQ.dcm",
  #       "rtplan_truncated.dcm"
  #     ])

  #   assert failing_files == expected_failing
  # end
end
