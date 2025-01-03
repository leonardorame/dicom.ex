defmodule Dicom.UidRegistry do
  @transfer_syntaxes %{
    "1.2.840.10008.1.2" => %{
      name: :implicit_vr_little_endian,
      options: [endianness: :little, explicit: false]
    },
    "1.2.840.10008.1.2.1" => %{
      name: :explicit_vr_little_endian,
      options: [endianness: :little, explicit: true]
    },
    "1.2.840.10008.1.2.2" => %{
      name: :explicit_vr_big_endian,
      options: [endianness: :big, explicit: true]
    },
    "1.2.840.10008.1.2.1.99" => %{
      name: :deflated_litte_endian_explicit_vr,
      options: [endianness: :little, explicit: true]
    },
    "1.2.840.10008.1.2.4.50" => %{
      name: :jpeg_baseline,
      options: [endianness: :little, explicit: true]
    },
    "1.2.840.10008.1.2.4.51" => %{
      name: :jpeg_extended,
      options: [endianness: :little, explicit: true]
    },
    "1.2.840.10008.1.2.4.57" => %{
      name: :jpeg_lossless_non_hierarchical,
      options: [endianness: :little, explicit: true]
    },
    "1.2.840.10008.1.2.4.70" => %{
      name: :jpeg_lossless_non_hierarchical_first_order_prediction,
      options: [endianness: :little, explicit: true]
    },
    "1.2.840.10008.1.2.4.80" => %{
      name: :jpeg_ls,
      options: [endianness: :little, explicit: true]
    },
    "1.2.840.10008.1.2.4.81" => %{
      name: :jpeg_ls_near_lossless,
      options: [endianness: :little, explicit: true]
    },
    "1.2.840.10008.1.2.4.90" => %{
      name: :jpeg2000_part1_lossless,
      options: [endianness: :little, explicit: true]
    },
    "1.2.840.10008.1.2.4.91" => %{
      name: :jpeg2000_part1_lossless_or_lossy,
      options: [endianness: :little, explicit: true]
    },
    "1.2.840.10008.1.2.4.92" => %{
      name: :jpeg2000_part2_lossless,
      options: [endianness: :little, explicit: true]
    },
    "1.2.840.10008.1.2.4.93" => %{
      name: :jpeg2000_part2_lossless_or_lossy,
      options: [endianness: :little, explicit: true]
    }
  }

  def get_transfer_syntax(uid) do
    Map.fetch!(@transfer_syntaxes, uid)
  end

  def get_default_transfer_syntax() do
    get_transfer_syntax("1.2.840.10008.1.2")
  end
end
