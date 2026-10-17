require "rails_helper"

RSpec.describe WorkspaceHelper, type: :helper do
  def upload_csv(name: "data.csv", content: "a,b\n1,2\n")
    file = create(:workspace_file, name: name)
    file.file.attach(
      io: StringIO.new(content),
      filename: name,
      content_type: "text/csv"
    )
    file
  end

  describe "#csv_preview" do
    it "parses headers and rows" do
      preview = helper.csv_preview(upload_csv(content: "name,age\nAda,36\nGrace,85\n"))

      expect(preview[:headers]).to eq([ "name", "age" ])
      expect(preview[:rows]).to eq([ [ "Ada", "36" ], [ "Grace", "85" ] ])
      expect(preview[:truncated]).to be false
    end

    it "pads ragged rows to a rectangular table" do
      preview = helper.csv_preview(upload_csv(content: "a,b,c\n1,2\n3,4,5,6\n"))

      expect(preview[:headers]).to eq([ "a", "b", "c", "" ])
      expect(preview[:rows]).to eq([ [ "1", "2", "", "" ], [ "3", "4", "5", "6" ] ])
    end

    it "returns empty headers and rows for an empty file" do
      preview = helper.csv_preview(upload_csv(content: ""))

      expect(preview).to eq({ headers: [], rows: [], truncated: false })
    end

    it "returns nil when nothing is attached" do
      expect(helper.csv_preview(create(:workspace_file))).to be_nil
    end

    it "returns nil for malformed CSV" do
      expect(helper.csv_preview(upload_csv(content: "a,b\n\"unclosed,quote\n"))).to be_nil
    end

    it "returns nil when the blob exceeds the byte cap" do
      stub_const("WorkspaceHelper::CSV_PREVIEW_MAX_BYTES", 1)

      expect(helper.csv_preview(upload_csv)).to be_nil
    end

    it "truncates long files and flags it" do
      stub_const("WorkspaceHelper::CSV_PREVIEW_MAX_ROWS", 2)
      content = "h\n" + (1..5).map { |i| "r#{i}" }.join("\n") + "\n"

      preview = helper.csv_preview(upload_csv(content: content))

      expect(preview[:rows]).to eq([ [ "r1" ], [ "r2" ] ])
      expect(preview[:truncated]).to be true
    end
  end
end
