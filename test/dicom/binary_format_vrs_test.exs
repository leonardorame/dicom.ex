defmodule Dicom.BinaryFormatVrsTest do
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
    },
    %{
      element: %DataElement{
        group_number: 0x0008,
        element_number: 0x0012,
        vr: :DA,
        values: ["20000101"]
      },
      explicit_vr_little_endian: "08001200444108003230303030313031",
      implicit_vr_little_endian: "08001200080000003230303030313031",
      explicit_vr_big_endian: "00080012444100083230303030313031"
    },
    %{
      element: %DataElement{
        group_number: 0x0010,
        element_number: 0x1020,
        vr: :DS,
        values: ["1.93"]
      },
      explicit_vr_little_endian: "1000201044530400312e3933",
      implicit_vr_little_endian: "1000201004000000312e3933",
      explicit_vr_big_endian: "0010102044530004312e3933"
    },
    %{
      element: %DataElement{
        group_number: 0x0008,
        element_number: 0x0015,
        vr: :DT,
        values: ["20240102131415"]
      },
      explicit_vr_little_endian: "0800150044540e003230323430313032313331343135",
      implicit_vr_little_endian: "080015000e0000003230323430313032313331343135",
      explicit_vr_big_endian: "000800154454000e3230323430313032313331343135"
    },
    %{
      element: %DataElement{
        group_number: 0x0018,
        element_number: 0x2046,
        vr: :FL,
        values: [1.234]
      },
      explicit_vr_little_endian: "18004620464c0400b6f39d3f",
      implicit_vr_little_endian: "1800462004000000b6f39d3f",
      explicit_vr_big_endian: "00182046464c00043f9df3b6"
    },
    %{
      element: %DataElement{
        group_number: 0x0008,
        element_number: 0x1163,
        vr: :FD,
        values: [1.23456789, 9.012345678]
      },
      explicit_vr_little_endian: "08006311464410001bde8342cac0f33f8f83362c52062240",
      implicit_vr_little_endian: "08006311100000001bde8342cac0f33f8f83362c52062240",
      explicit_vr_big_endian: "00081163464400103ff3c0ca4283de1b402206522c36838f"
    },
    %{
      element: %DataElement{
        group_number: 0x0008,
        element_number: 0x1160,
        vr: :IS,
        values: ["123"]
      },
      explicit_vr_little_endian: "080060114953040031323320",
      implicit_vr_little_endian: "080060110400000031323320",
      explicit_vr_big_endian: "000811604953000431323320"
    },
    %{
      element: %DataElement{
        group_number: 0x0008,
        element_number: 0x0070,
        vr: :LO,
        values: ["LONGSTRING"]
      },
      explicit_vr_little_endian: "080070004c4f0a004c4f4e47535452494e47",
      implicit_vr_little_endian: "080070000a0000004c4f4e47535452494e47",
      explicit_vr_big_endian: "000800704c4f000a4c4f4e47535452494e47"
    },
    %{
      element: %DataElement{
        group_number: 0x0008,
        element_number: 0x0108,
        vr: :LT,
        values: ["LONGTEXT"]
      },
      explicit_vr_little_endian: "080008014c5408004c4f4e4754455854",
      implicit_vr_little_endian: "08000801080000004c4f4e4754455854",
      explicit_vr_big_endian: "000801084c5400084c4f4e4754455854"
    },
    %{
      element: %DataElement{
        group_number: 0x0014,
        element_number: 0x2210,
        vr: :OB,
        values: [<<0x31, 0x32, 0x33, 0x34>>]
      },
      explicit_vr_little_endian: "140010224f4200000400000031323334",
      implicit_vr_little_endian: "140010220400000031323334",
      explicit_vr_big_endian: "001422104f4200000000000431323334"
    },
    %{
      element: %DataElement{
        group_number: 0x0028,
        element_number: 0x1408,
        vr: :OW,
        values: ["otherword\0"]
      },
      explicit_vr_little_endian: "280008144f5700000a0000006f74686572776f726400",
      implicit_vr_little_endian: "280008140a0000006f74686572776f726400",
      explicit_vr_big_endian: "002814084f5700000000000a6f74686572776f726400"
    },
    %{
      element: %DataElement{
        group_number: 0x0010,
        element_number: 0x0010,
        vr: :PN,
        values: ["Doe^John"]
      },
      explicit_vr_little_endian: "10001000504e0800446f655e4a6f686e",
      implicit_vr_little_endian: "1000100008000000446f655e4a6f686e",
      explicit_vr_big_endian: "00100010504e0008446f655e4a6f686e"
    },
    %{
      element: %DataElement{
        group_number: 0x0008,
        element_number: 0x0050,
        vr: :SH,
        values: ["SHORTSTRING"]
      },
      explicit_vr_little_endian: "0800500053480c0053484f5254535452494e4720",
      implicit_vr_little_endian: "080050000c00000053484f5254535452494e4720",
      explicit_vr_big_endian: "000800505348000c53484f5254535452494e4720"
    },
    %{
      element: %DataElement{
        group_number: 0x0072,
        element_number: 0x007C,
        vr: :SL,
        values: [-2_147_483_648, 2_147_483_647]
      },
      explicit_vr_little_endian: "72007c00534c080000000080ffffff7f",
      implicit_vr_little_endian: "72007c000800000000000080ffffff7f",
      explicit_vr_big_endian: "0072007c534c0008800000007fffffff"
    },
    %{
      element: %DataElement{
        group_number: 0x0072,
        element_number: 0x007E,
        vr: :SS,
        values: [-32768, 32767]
      },
      explicit_vr_little_endian: "72007e00535304000080ff7f",
      implicit_vr_little_endian: "72007e00040000000080ff7f",
      explicit_vr_big_endian: "0072007e5353000480007fff"
    },
    %{
      element: %DataElement{
        group_number: 0x0008,
        element_number: 0x0081,
        vr: :ST,
        values: ["SHORTTEXT"]
      },
      explicit_vr_little_endian: "0800810053540a0053484f52545445585420",
      implicit_vr_little_endian: "080081000a00000053484f52545445585420",
      explicit_vr_big_endian: "000800815354000a53484f52545445585420"
    },
    %{
      element: %DataElement{
        group_number: 0x0072,
        element_number: 0x0082,
        vr: :SV,
        values: [-9_223_372_036_854_775_808, 9_223_372_036_854_775_807]
      },
      explicit_vr_little_endian: "7200820053560000100000000000000000000080ffffffffffffff7f",
      implicit_vr_little_endian: "72008200100000000000000000000080ffffffffffffff7f",
      explicit_vr_big_endian: "00720082535600000000001080000000000000007fffffffffffffff"
    },
    %{
      element: %DataElement{
        group_number: 0x0008,
        element_number: 0x0013,
        vr: :TM,
        values: ["111213.123456"]
      },
      explicit_vr_little_endian: "08001300544d0e003131313231332e31323334353620",
      implicit_vr_little_endian: "080013000e0000003131313231332e31323334353620",
      explicit_vr_big_endian: "00080013544d000e3131313231332e31323334353620"
    },
    %{
      element: %DataElement{
        group_number: 0x0008,
        element_number: 0x0119,
        vr: :UC,
        # TODO: this has an additional trailing space because lenght is uneven
        # I'm not yet sure how this is properly handled
        values: ["  padded characters   "]
      },
      explicit_vr_little_endian:
        "08001901554300001600000020207061646465642063686172616374657273202020",
      implicit_vr_little_endian: "080019011600000020207061646465642063686172616374657273202020",
      explicit_vr_big_endian:
        "00080119554300000000001620207061646465642063686172616374657273202020"
    },
    %{
      element: %DataElement{
        group_number: 0x0004,
        element_number: 0x1432,
        vr: :UI,
        values: ["1.2.3.4"]
      },
      explicit_vr_little_endian: "0400321455490800312e322e332e3400",
      implicit_vr_little_endian: "0400321408000000312e322e332e3400",
      explicit_vr_big_endian: "0004143255490008312e322e332e3400"
    },
    %{
      element: %DataElement{
        group_number: 0x0018,
        element_number: 0x6046,
        vr: :UL,
        values: [42]
      },
      explicit_vr_little_endian: "18004660554c04002a000000",
      implicit_vr_little_endian: "18004660040000002a000000",
      explicit_vr_big_endian: "00186046554c00040000002a"
    },
    %{
      element: %DataElement{
        group_number: 0x0008,
        element_number: 0x0120,
        vr: :UR,
        values: ["urn:some-urn"]
      },
      explicit_vr_little_endian: "08002001555200000c00000075726e3a736f6d652d75726e",
      implicit_vr_little_endian: "080020010c00000075726e3a736f6d652d75726e",
      explicit_vr_big_endian: "00080120555200000000000c75726e3a736f6d652d75726e"
    },
    %{
      element: %DataElement{
        group_number: 0x0072,
        element_number: 0x006D,
        vr: :UN,
        values: ["unknown"]
      },
      explicit_vr_little_endian: "72006d00554e000007000000756e6b6e6f776e",
      implicit_vr_little_endian: "72006d0007000000756e6b6e6f776e",
      explicit_vr_big_endian: "0072006d554e000000000007756e6b6e6f776e"
    },
    %{
      element: %DataElement{
        group_number: 0x0008,
        element_number: 0x0040,
        vr: :US,
        values: [1]
      },
      explicit_vr_little_endian: "08004000555302000100",
      implicit_vr_little_endian: "08004000020000000100",
      explicit_vr_big_endian: "00080040555300020001"
    },
    %{
      element: %DataElement{
        group_number: 0x0016,
        element_number: 0x0003,
        vr: :UT,
        values: ["UNLIMITEDTEXT"]
      },
      explicit_vr_little_endian: "16000300555400000e000000554e4c494d495445445445585420",
      implicit_vr_little_endian: "160003000e000000554e4c494d495445445445585420",
      explicit_vr_big_endian: "00160003555400000000000e554e4c494d495445445445585420"
    },
    %{
      element: %DataElement{
        group_number: 0x0008,
        element_number: 0x0428,
        vr: :UV,
        values: [42_424_242]
      },
      explicit_vr_little_endian: "080028045556000008000000b257870200000000",
      implicit_vr_little_endian: "0800280408000000b257870200000000",
      explicit_vr_big_endian: "00080428555600000000000800000000028757b2"
    },
    %{
      element: %DataElement{
        group_number: 0x4243,
        element_number: 0x0010,
        vr: :LO,
        values: ["Private Block 01"]
      },
      explicit_vr_little_endian: "434210004c4f10005072697661746520426c6f636b203031",
      implicit_vr_little_endian: "43421000100000005072697661746520426c6f636b203031",
      explicit_vr_big_endian: "424300104c4f00105072697661746520426c6f636b203031"
    },
    %{
      element: %DataElement{
        group_number: 0x0008,
        element_number: 0x1115,
        vr: :SQ,
        values: [
          DataSet.from_keyword_list(SeriesInstanceUID: "1.2"),
          DataSet.from_keyword_list(SeriesInstanceUID: "1.3")
        ]
      },
      explicit_vr_little_endian:
        "080015115351000028000000feff00e00c00000020000e0055490400312e3200feff00e00c00000020000e0055490400312e3300",
      implicit_vr_little_endian:
        "0800151128000000feff00e00c00000020000e0004000000312e3200feff00e00c00000020000e0004000000312e3300",
      explicit_vr_big_endian:
        "000811155351000000000028fffee0000000000c0020000e55490004312e3200fffee0000000000c0020000e55490004312e3300"
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

  @comparison_precision_decimals 5

  defp assert_data_elements_equal(actual, expected) do
    # round float values to a fixed precision
    {actual, expected} =
      if expected.vr in [:FL, :FD] do
        {
          %DataElement{
            actual
            | values: actual.values |> Enum.map(&Float.round(&1, @comparison_precision_decimals))
          },
          %DataElement{
            expected
            | values:
                expected.values |> Enum.map(&Float.round(&1, @comparison_precision_decimals))
          }
        }
      else
        {actual, expected}
      end

    assert actual == expected
  end

  test "serializes data element", %{sample: sample, ts: ts} do
    options =
      case ts do
        :explicit_vr_little_endian -> [endianness: :little, explicit: true]
        :implicit_vr_little_endian -> [endianness: :little, explicit: false]
        :explicit_vr_big_endian -> [endianness: :big, explicit: true]
      end

    # TODO: SQ serialization not yet supported
    if sample[:element].vr != :SQ do
      actual = BinaryFormat.serialize_data_element(sample[:element], options)
      expected = :binary.decode_hex(sample[ts])

      assert actual == expected
    end
  end

  test "parses data element", %{sample: sample, ts: ts} do
    options =
      case ts do
        :explicit_vr_little_endian -> [endianness: :little, explicit: true]
        :implicit_vr_little_endian -> [endianness: :little, explicit: false]
        :explicit_vr_big_endian -> [endianness: :big, explicit: true]
      end

    expected_element = sample[:element]

    {:ok, {actual_element, <<>>}} =
      BinaryFormat.read_next_data_element(:binary.decode_hex(sample[ts]), options)

    assert_data_elements_equal(actual_element, expected_element)
  end
end
