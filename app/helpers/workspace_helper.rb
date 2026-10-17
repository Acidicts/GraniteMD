require "csv"

module WorkspaceHelper
  # Largest blob we'll parse for an inline CSV preview (bytes). Parsing is
  # bounded by this cap so a huge upload can't blow up the preview render.
  CSV_PREVIEW_MAX_BYTES = 1_048_576
  # Rows rendered before the table is cut off with a "truncated" note.
  CSV_PREVIEW_MAX_ROWS = 500

  # Parses an attached CSV for inline preview.
  # Returns { headers: [...], rows: [[...]], truncated: bool }, or nil when
  # the file can't be previewed (nothing attached, too large, malformed).
  # All values are plain strings; the view escapes them on render.
  def csv_preview(workspace_file)
    attachment = workspace_file.file
    return nil unless attachment.attached?
    return nil if attachment.blob.byte_size > CSV_PREVIEW_MAX_BYTES

    text = attachment.download.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    text = text.delete_prefix("\uFEFF")
    table = CSV.parse(text, headers: true)

    headers = (table.headers || []).map(&:to_s)
    width = headers.length
    sample = table.first(CSV_PREVIEW_MAX_ROWS + 1)
    truncated = sample.length > CSV_PREVIEW_MAX_ROWS
    rows = sample.first(CSV_PREVIEW_MAX_ROWS).map do |row|
      fields = row.fields.map(&:to_s)
      width = [ width, fields.length ].max
      fields
    end
    rows.each { |row| row.fill("", row.length...width) }
    headers.fill("", headers.length...width)

    { headers: headers, rows: rows, truncated: truncated }
  rescue CSV::MalformedCSVError, EncodingError, ArgumentError
    nil
  end
end
