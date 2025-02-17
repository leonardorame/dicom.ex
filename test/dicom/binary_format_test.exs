defmodule Dicom.BinaryFormatTest do
  alias Dicom.DataElement
  alias Dicom.DataSet
  alias Dicom.BinaryFormat

  @samples [
    %{
      element: %DataElement{
        group_number: 0x0008,
        element_number: 0x0055,
        vr: :AE,
        values: ["AETITLE"]
      },
      explicit_vr_little_endian: "080055004145080041455449544c4520",
      implicit_vr_little_endian: "080055000800000041455449544c4520",
      explicit_vr_big_endian: "000800554145000841455449544c4520"
    },
    %{
      element: %DataElement{
        group_number: 0x0010,
        element_number: 0x1010,
        vr: :AS,
        values: ["042Y"]
      },
      explicit_vr_little_endian: "100010104153040030343259",
      implicit_vr_little_endian: "100010100400000030343259",
      explicit_vr_big_endian: "001010104153000430343259"
    },
    %{
      element: %DataElement{
        group_number: 0x0014,
        element_number: 0x0202,
        vr: :AT,
        values: [0x00020010]
      },
      explicit_vr_little_endian: "140002024154040002001000",
      implicit_vr_little_endian: "140002020400000002001000",
      explicit_vr_big_endian: "001402024154000400020010"
    },
    %{
      element: %DataElement{
        group_number: 0x0008,
        element_number: 0x0008,
        vr: :CS,
        values: ["CODESTRING"]
      },
      explicit_vr_little_endian: "0800080043530a00434f4445535452494e47",
      implicit_vr_little_endian: "080008000a000000434f4445535452494e47",
      explicit_vr_big_endian: "000800084353000a434f4445535452494e47"
    }
  ]

  use ExUnit.Case,
    async: true,
    parameterize:
      for(
        sample <- @samples,
        ts <- [:explicit_vr_little_endian, :implicit_vr_little_endian, :explicit_vr_big_endian],
        do: %{sample: sample, ts: ts}
      )

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

  test "parses data element", %{sample: sample, ts: ts} do
    IO.inspect({sample[:element].vr, ts})

    options =
      case ts do
        :explicit_vr_little_endian -> [endianness: :little, explicit: true]
        :implicit_vr_little_endian -> [endianness: :little, explicit: false]
        :explicit_vr_big_endian -> [endianness: :big, explicit: true]
      end

    expected_element = sample[:element]

    {:ok, {actual_element, <<>>}} =
      BinaryFormat.read_next_data_element(:binary.decode_hex(sample[ts]), options)

    assert actual_element == expected_element
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

  test "parses long string (LO) fields" do
    expected = %DataElement{
      group_number: 0x0008,
      element_number: 0x0070,
      vr: :LO,
      values: ["LONGSTRING"]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "080070004c4f0a004c4f4e47535452494e47"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "000800704c4f000a4c4f4e47535452494e47"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "080070000a0000004c4f4e47535452494e47"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses long text (LT) fields" do
    expected = %DataElement{
      group_number: 0x0008,
      element_number: 0x0108,
      vr: :LT,
      values: ["LONGTEXT"]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "080008014c5408004c4f4e4754455854"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "000801084c5400084c4f4e4754455854"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "08000801080000004c4f4e4754455854"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses other binary (OB) fields" do
    expected = %DataElement{
      group_number: 0x0014,
      element_number: 0x2210,
      vr: :OB,
      values: [<<0x31, 0x32, 0x33, 0x34>>]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "140010224f4200000400000031323334"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "001422104f4200000000000431323334"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "140010220400000031323334"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses other word (OW) fields" do
    expected = %DataElement{
      group_number: 0x0028,
      element_number: 0x1408,
      vr: :OW,
      values: ["otherword\0"]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "280008144f5700000a0000006f74686572776f726400"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "002814084f5700000000000a6f74686572776f726400"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "280008140a0000006f74686572776f726400"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses patient name (PN) fields" do
    expected = %DataElement{
      group_number: 0x0010,
      element_number: 0x0010,
      vr: :PN,
      values: ["Doe^John"]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "10001000504e0800446f655e4a6f686e"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "00100010504e0008446f655e4a6f686e"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "1000100008000000446f655e4a6f686e"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses short string (SH) fields" do
    expected = %DataElement{
      group_number: 0x0008,
      element_number: 0x0050,
      vr: :SH,
      values: ["SHORTSTRING"]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "0800500053480c0053484f5254535452494e4720"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "000800505348000c53484f5254535452494e4720"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "080050000c00000053484f5254535452494e4720"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses signed long (SL) fields" do
    expected = %DataElement{
      group_number: 0x0072,
      element_number: 0x007C,
      vr: :SL,
      values: [-42]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "72007c00534c0400d6ffffff"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "0072007c534c0004ffffffd6"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "72007c0004000000d6ffffff"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses signed short (SS) fields" do
    expected = %DataElement{
      group_number: 0x0072,
      element_number: 0x007E,
      vr: :SS,
      values: [-42]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "72007e0053530200d6ff"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "0072007e53530002ffd6"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "72007e0002000000d6ff"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses short text (ST) fields" do
    expected = %DataElement{
      group_number: 0x0008,
      element_number: 0x0081,
      vr: :ST,
      values: ["SHORTTEXT"]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "0800810053540a0053484f52545445585420"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "000800815354000a53484f52545445585420"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "080081000a00000053484f52545445585420"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses signed very long (SV) fields" do
    expected = %DataElement{
      group_number: 0x0072,
      element_number: 0x0082,
      vr: :SV,
      values: [-9_223_372_036_854_775_808, 9_223_372_036_854_775_807]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "7200820053560000100000000000000000000080ffffffffffffff7f"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "00720082535600000000001080000000000000007fffffffffffffff"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "72008200100000000000000000000080ffffffffffffff7f"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses time (TM) fields" do
    expected = %DataElement{
      group_number: 0x0008,
      element_number: 0x0013,
      vr: :TM,
      values: ["111213.123456"]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "08001300544d0e003131313231332e31323334353620"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "00080013544d000e3131313231332e31323334353620"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "080013000e0000003131313231332e31323334353620"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses unlimited characters (UC) fields" do
    expected = %DataElement{
      group_number: 0x0008,
      element_number: 0x0119,
      vr: :UC,
      # TODO: this has an additional trailing space because lenght is uneven
      # I'm not yet sure how this is properly handled
      values: ["  padded characters   "]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "08001901554300001600000020207061646465642063686172616374657273202020"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "00080119554300000000001620207061646465642063686172616374657273202020"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "080019011600000020207061646465642063686172616374657273202020"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses unique identifier (UI) fields" do
    expected = %DataElement{
      group_number: 0x0004,
      element_number: 0x1432,
      vr: :UI,
      values: ["1.2.3.4"]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "0400321455490800312e322e332e3400"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "0004143255490008312e322e332e3400"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "0400321408000000312e322e332e3400"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses unsigned long (UL) fields" do
    expected = %DataElement{
      group_number: 0x0018,
      element_number: 0x6046,
      vr: :UL,
      values: [42]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "18004660554c04002a000000"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "00186046554c00040000002a"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "18004660040000002a000000"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses univeral resource identifier/locator (UR) fields" do
    expected = %DataElement{
      group_number: 0x0008,
      element_number: 0x0120,
      vr: :UR,
      values: ["urn:some-urn"]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "08002001555200000c00000075726e3a736f6d652d75726e"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "00080120555200000000000c75726e3a736f6d652d75726e"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "080020010c00000075726e3a736f6d652d75726e"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses unknown VR (UN) fields" do
    expected = %DataElement{
      group_number: 0x0072,
      element_number: 0x006D,
      vr: :UN,
      values: ["unknown"]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "72006d00554e000007000000756e6b6e6f776e"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "0072006d554e000000000007756e6b6e6f776e"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "72006d0007000000756e6b6e6f776e"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses unsigned short (US) fields" do
    expected = %DataElement{
      group_number: 0x0008,
      element_number: 0x0040,
      vr: :US,
      values: [1]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "08004000555302000100"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "00080040555300020001"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "08004000020000000100"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses unlimited text (UT) fields" do
    expected = %DataElement{
      group_number: 0x0016,
      element_number: 0x0003,
      vr: :UT,
      values: ["UNLIMITEDTEXT"]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "16000300555400000e000000554e4c494d495445445445585420"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "00160003555400000000000e554e4c494d495445445445585420"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "160003000e000000554e4c494d495445445445585420"
    }

    assert_sample_parses_correctly(sample, expected)
  end

  test "parses unsigned very long (UV) fields" do
    expected = %DataElement{
      group_number: 0x0008,
      element_number: 0x0428,
      vr: :UV,
      values: [42_424_242]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "080028045556000008000000b257870200000000"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "00080428555600000000000800000000028757b2"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "0800280408000000b257870200000000"
    }

    assert_sample_parses_correctly(sample, expected)
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

  test "parses private fields" do
    expected = %DataElement{
      group_number: 0x4243,
      element_number: 0x0010,
      vr: :LO,
      values: ["Private Block 01"]
    }

    sample = %{
      options: [endianness: :little, explicit: true],
      data: "434210004c4f10005072697661746520426c6f636b203031"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :big, explicit: true],
      data: "424300104c4f00105072697661746520426c6f636b203031"
    }

    assert_sample_parses_correctly(sample, expected)

    sample = %{
      options: [endianness: :little, explicit: false],
      data: "43421000100000005072697661746520426c6f636b203031"
    }

    assert_sample_parses_correctly(sample, expected)
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
