module AlertsHelper
  ALERT_ROLES = { error: "alert", warn: "status", info: "status" }.freeze

  FLASH_TYPES = { alert: :error, warn: :warn, notice: :info, info: :info }.freeze

  ALERT_ICON_SHAPES = {
    error: [
      { circle: { cx: 12, cy: 12, r: 10 } },
      { path: { d: "m15 9-6 6" } },
      { path: { d: "m9 9 6 6" } }
    ],
    warn: [
      { path: { d: "m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3" } },
      { path: { d: "M12 9v4" } },
      { path: { d: "M12 17h.01" } }
    ],
    info: [
      { circle: { cx: 12, cy: 12, r: 10 } },
      { path: { d: "M12 16v-4" } },
      { path: { d: "M12 8h.01" } }
    ],
    dismiss: [
      { path: { d: "M18 6 6 18" } },
      { path: { d: "m6 6 12 12" } }
    ]
  }.freeze

  def flash_alerts
    box = flash[:alert_box]
    box = box.symbolize_keys if box.is_a?(Hash)
    messages = box ? [ alert_box(box[:type], title: box[:title], message: box[:message]) ] : []

    messages += FLASH_TYPES.filter_map do |key, type|
      flash[key].present? && alert_box(type, message: flash[key])
    end

    return if messages.empty?

    tag.div(safe_join(messages), class: "flash-rail")
  end

  def alert(error: nil, warn: nil, info: nil, title: nil, **options)
    type, message =
      if error.present?
        [ :error, error ]
      elsif warn.present?
        [ :warn, warn ]
      elsif info.present?
        [ :info, info ]
      end

    return if message.blank?

    message = safe_join([ "#{type.to_s.capitalize}:", message ], " ") if title.blank?

    alert_box(type, title: title.presence, message: message, **options)
  end

  def alert_box(type, title: nil, message: nil, action: nil, compact: false, dismissible: true, role: nil, &block)
    type = type.to_sym
    message = capture(&block) if block_given?

    classes = [ "alert", "alert-#{type}" ]
    classes << "alert-compact" if compact

    content = if compact
      tag.span(message, class: "alert-message")
    else
      tag.div(alert_body(title, message, action), class: "alert-body")
    end

    children = [ alert_icon(type), content ]
    children << alert_dismiss_button if dismissible && !compact

    tag.div(safe_join(children),
            class: classes.join(" "),
            role: role || ALERT_ROLES.fetch(type, "status"))
  end

  private

  def alert_body(title, message, action)
    parts = []
    parts << tag.div(title, class: "alert-title") if title
    parts << tag.div(message, class: "alert-message") if message

    if action
      label, href = action
      parts << link_to(label, href, class: "alert-action")
    end

    safe_join(parts)
  end

  def alert_icon(type)
    tag.svg(safe_join(alert_icon_shapes(type)), class: "alert-icon", viewBox: "0 0 24 24",
            "aria-hidden": "true", focusable: "false")
  end

  def alert_dismiss_button
    tag.button(safe_join(alert_icon_shapes(:dismiss)), class: "alert-dismiss", type: "button",
               aria: { label: "Dismiss" }, data: { action: "alert#dismiss" })
  end

  def alert_icon_shapes(type)
    ALERT_ICON_SHAPES.fetch(type, ALERT_ICON_SHAPES[:info]).map do |shape|
      if shape.key?(:circle)
        tag.circle(**shape[:circle])
      else
        tag.path(**shape[:path])
      end
    end
  end
end
