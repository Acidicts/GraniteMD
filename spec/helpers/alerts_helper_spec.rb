require "rails_helper"

RSpec.describe AlertsHelper, type: :helper do
  describe "#alert_box" do
    it "builds a full alert with title, message, action and dismiss" do
      html = helper.alert_box(:error,
                              title: "Couldn't save README.md",
                              message: "The file is read-only.",
                              action: [ "Try again", "/retry" ])

      expect(html).to include('class="alert alert-error"')
      expect(html).to include('role="alert"')
      expect(html).to include('class="alert-title"')
      expect(html).to include("The file is read-only.")
      expect(html).to include('class="alert-action"')
      expect(html).to include('href="/retry"')
      expect(html).to include('class="alert-dismiss"')
      expect(html).to include('data-action="alert#dismiss"')
    end

    it "builds a compact alert as a single line with status role" do
      html = helper.alert_box(:warn, message: "This note is over 10,000 words", compact: true)

      expect(html).to include('class="alert alert-warn alert-compact"')
      expect(html).to include('role="status"')
      expect(html).to include('<span class="alert-message">')
      expect(html).not_to include("alert-dismiss")
      expect(html).not_to include("alert-title")
    end
  end

  describe "#alert" do
    it "prefixes the message with the type when no title is given" do
      html = helper.alert(error: "Couldn't save README.md")

      expect(html).to include('class="alert alert-error"')
      expect(html).to include('role="alert"')
      expect(html).to include("Error: Couldn&#39;t save README.md")
      expect(html).not_to include("alert-title")
    end

    it "shows title and message separately when a title is given" do
      html = helper.alert(warn: "This note is over 10,000 words", title: "Long note")

      expect(html).to include('class="alert alert-warn"')
      expect(html).to include('role="status"')
      expect(html).to include('class="alert-title"')
      expect(html).to include("Long note")
      expect(html).to include("This note is over 10,000 words")
      expect(html).not_to include("Warn:")
    end

    it "uses the status role for info alerts and forwards options" do
      html = helper.alert(info: "Draft saved", compact: true)

      expect(html).to include('class="alert alert-info alert-compact"')
      expect(html).to include('role="status"')
      expect(html).to include("Info: Draft saved")
    end

    it "renders nothing without a message" do
      expect(helper.alert).to be_nil
      expect(helper.alert(error: "")).to be_nil
    end
  end

  describe "#flash_alerts" do
    it "maps flash keys to alert types" do
      allow(helper).to receive(:flash).and_return(
        alert: "Wrong password",
        warn: "Cache is still warming up",
        notice: "Profile updated"
      )

      html = helper.flash_alerts

      expect(html).to include('class="flash-rail"')
      expect(html).to include('class="alert alert-error"')
      expect(html).to include('class="alert alert-warn"')
      expect(html).to include('class="alert alert-info"')
      expect(html).to include('role="alert"')
      expect(html).to include("Wrong password")
      expect(html).to include("Cache is still warming up")
      expect(html).to include("Profile updated")
    end

    it "renders nothing when flash is empty" do
      allow(helper).to receive(:flash).and_return({})

      expect(helper.flash_alerts).to be_nil
    end
  end
end
