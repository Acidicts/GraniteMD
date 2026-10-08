module WorkspacesHelper
  STORAGE_UNITS = %w[B KB MB GB TB].freeze

  # 1023B, 1KB, 1.12KB, 1023KB, 1MB, 1.12MB — base 1024, max 2 decimals.
  def human_storage_size(bytes)
    bytes = bytes.to_i
    return "0B" if bytes <= 0

    exp = (Math.log(bytes) / Math.log(1024)).floor.clamp(0, STORAGE_UNITS.size - 1)
    value = bytes.to_f / (1024**exp)
    formatted = exp.zero? ? value.to_i.to_s : number_with_precision(value, precision: 2, strip_insignificant_zeros: true)
    "#{formatted}#{STORAGE_UNITS[exp]}"
  end
end
