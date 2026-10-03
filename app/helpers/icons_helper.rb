module IconsHelper
  GEM_SHADES = [
    %w[#f0a0a0 #d86a6a], # shade-1 (lightest)
    %w[#c24a4a #a53636], # shade-2
    %w[#8c2828 #701d1d], # shade-3
    %w[#5a1414 #410d0d]  # shade-4 (darkest)
  ].freeze

  GEM_FACETS = [
    [ "140,330 185,360 165,400", 3 ],
    [ "165,400 185,360 220,410", 2 ],
    [ "185,360 235,355 220,410", 1 ],
    [ "140,330 185,305 185,360", 2 ],
    [ "185,360 235,310 235,355", 1 ],
    [ "235,355 280,380 220,410", 4 ],
    [ "235,355 285,340 280,380", 2 ]
  ].freeze

  def logo_svg(width: 0, height: 0, shades: GEM_SHADES)
    gradients = shades.each_with_index.map do |(from, to), i|
      content_tag(:linearGradient,
                  safe_join([
                              tag.stop(offset: 0, "stop-color": from),
                    tag.stop(offset: 1, "stop-color": to)
                            ]),
                  id: "gem-g#{i + 1}", x1: 0, y1: 0, x2: 1, y2: 1)
    end

    # Fine grain = the semi-matte surface
    matte = content_tag(:filter,
                        safe_join([
                                    content_tag(:feTurbulence, nil, type: "fractalNoise", baseFrequency: "0.9",
                                                numOctaves: 2, seed: 4, result: "n"),
                          content_tag(:feColorMatrix, nil, in: "n", type: "matrix", result: "grain",
                                      values: "0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 0.07 0"),
                          content_tag(:feComposite, nil, in: "grain", in2: "SourceGraphic",
                                      operator: "in", result: "g"),
                          content_tag(:feMerge,
                                      safe_join([
                                                  content_tag(:feMergeNode, nil, in: "SourceGraphic"),
                                        content_tag(:feMergeNode, nil, in: "g")
                                                ]))
                                  ]),
                        id: "gem-matte", x: 0, y: 0, width: "100%", height: "100%")

    # Soft highlight over the whole stone
    sheen = content_tag(:radialGradient,
                        safe_join([
                                    tag.stop(offset: 0, "stop-color": "#fff", "stop-opacity": 0.16),
                          tag.stop(offset: 1, "stop-color": "#fff", "stop-opacity": 0)
                                  ]),
                        id: "gem-sheen", cx: 0.35, cy: 0.3, r: 0.7)

    facets = GEM_FACETS.map do |points, shade|
      tag.polygon(points: points, fill: "url(#gem-g#{shade})",
                  stroke: "rgba(255,255,255,0.22)", "stroke-width": 0.8,
                  "stroke-linejoin": "round")
    end

    overlay = tag.polygon(
      points: "140,330 185,305 235,310 285,340 280,380 220,410 165,400",
      fill: "url(#gem-sheen)", "pointer-events": "none")

    content_tag(:svg,
                safe_join([
                            tag.defs(safe_join([ *gradients, matte, sheen ])),
                  tag.g(safe_join([ *facets, overlay ]), filter: "url(#gem-matte)")
                          ]),
                xmlns: "http://www.w3.org/2000/svg", viewBox: "135 300 155 115",
                preserveAspectRatio: "xMidYMid meet", width: width, height: height,
                aria: { label: "gem-badge" }
               )
  end

  DASHBOARD_ICON_PATH = "M6.25 10.5C6.25 10.0858 5.91421 9.75 5.5 9.75C5.08579 9.75 4.75 10.0858 4.75 10.5H6.25ZM11.5 19.75C11.9142 19.75 12.25 19.4142 12.25 19C12.25 18.5858 11.9142 18.25 11.5 18.25V19.75ZM4.75 10.5C4.75 10.9142 5.08579 11.25 5.5 11.25C5.91421 11.25 6.25 10.9142 6.25 10.5H4.75ZM11.5 5.75C11.9142 5.75 12.25 5.41421 12.25 5C12.25 4.58579 11.9142 4.25 11.5 4.25V5.75ZM5.5 9.75C5.08579 9.75 4.75 10.0858 4.75 10.5C4.75 10.9142 5.08579 11.25 5.5 11.25V9.75ZM11.5 11.25C11.9142 11.25 12.25 10.9142 12.25 10.5C12.25 10.0858 11.9142 9.75 11.5 9.75V11.25ZM10.75 10.5C10.75 10.9142 11.0858 11.25 11.5 11.25C11.9142 11.25 12.25 10.9142 12.25 10.5H10.75ZM12.25 5C12.25 4.58579 11.9142 4.25 11.5 4.25C11.0858 4.25 10.75 4.58579 10.75 5H12.25ZM12.25 10.5C12.25 10.0858 11.9142 9.75 11.5 9.75C11.0858 9.75 10.75 10.0858 10.75 10.5H12.25ZM10.75 14C10.75 14.4142 11.0858 14.75 11.5 14.75C11.9142 14.75 12.25 14.4142 12.25 14H10.75ZM11.5 18.25C11.0858 18.25 10.75 18.5858 10.75 19C10.75 19.4142 11.0858 19.75 11.5 19.75V18.25ZM20.25 14C20.25 13.5858 19.9142 13.25 19.5 13.25C19.0858 13.25 18.75 13.5858 18.75 14H20.25ZM10.75 19C10.75 19.4142 11.0858 19.75 11.5 19.75C11.9142 19.75 12.25 19.4142 12.25 19H10.75ZM12.25 14C12.25 13.5858 11.9142 13.25 11.5 13.25C11.0858 13.25 10.75 13.5858 10.75 14H12.25ZM11.5 4.25C11.0858 4.25 10.75 4.58579 10.75 5C10.75 5.41421 11.0858 5.75 11.5 5.75V4.25ZM18.75 14C18.75 14.4142 19.0858 14.75 19.5 14.75C19.9142 14.75 20.25 14.4142 20.25 14H18.75ZM19.5 14.75C19.9142 14.75 20.25 14.4142 20.25 14C20.25 13.5858 19.9142 13.25 19.5 13.25V14.75ZM11.5 13.25C11.0858 13.25 10.75 13.5858 10.75 14C10.75 14.4142 11.0858 14.75 11.5 14.75V13.25ZM4.75 10.5L4.75 15H6.25L6.25 10.5H4.75ZM4.75 15C4.75 17.6234 6.87665 19.75 9.5 19.75V18.25C7.70507 18.25 6.25 16.7949 6.25 15H4.75ZM9.5 19.75H11.5V18.25H9.5V19.75ZM6.25 10.5V9H4.75V10.5H6.25ZM6.25 9C6.25 7.20507 7.70507 5.75 9.5 5.75V4.25C6.87665 4.25 4.75 6.37665 4.75 9H6.25ZM9.5 5.75H11.5V4.25H9.5V5.75ZM5.5 11.25H11.5V9.75H5.5V11.25ZM12.25 10.5V5H10.75V10.5H12.25ZM10.75 10.5V14H12.25V10.5H10.75ZM11.5 19.75H15.5V18.25H11.5V19.75ZM15.5 19.75C18.1234 19.75 20.25 17.6234 20.25 15H18.75C18.75 16.7949 17.2949 18.25 15.5 18.25V19.75ZM20.25 15V14H18.75V15H20.25ZM12.25 19V14H10.75V19H12.25ZM11.5 5.75H15.5L15.5 4.25H11.5V5.75ZM15.5 5.75C17.2949 5.75 18.75 7.20507 18.75 9L20.25 9C20.25 6.37665 18.1234 4.25 15.5 4.25L15.5 5.75ZM18.75 9V14H20.25V9L18.75 9ZM19.5 13.25H11.5V14.75H19.5V13.25Z".freeze

  def dashboard_icon(width: 0, height: 0, color: "currentColor")
    content_tag(:svg,
                tag.path(d: DASHBOARD_ICON_PATH, fill: color),
                xmlns: "http://www.w3.org/2000/svg", viewBox: "0 -0.5 25 25",
                fill: "none", preserveAspectRatio: "xMidYMid meet",
                width: width, height: height,
                aria: { label: "dashboard-icon" }
               )
  end

  def profile_svg(width: 0, height: 0, color: "#B7A878", background: "#E5E7EB")
    clip_id = "profile-clip-#{SecureRandom.hex(4)}"

    content_tag(:svg,
                xmlns: "http://www.w3.org/2000/svg",
                viewBox: "0 0 128 128",
                preserveAspectRatio: "xMidYMid meet",
                width: width, height: height,
                role: "img", aria: { label: "user" }) do
      safe_join([
                  tag.defs(content_tag(:clipPath, tag.circle(cx: 64, cy: 64, r: 64), id: clip_id)),
        tag.circle(cx: 64, cy: 64, r: 64, fill: background),
        tag.g("clip-path": "url(##{clip_id})", fill: color) do
          safe_join([
                      tag.circle(cx: 64, cy: 48, r: 22),
            tag.path(d: "M16 128c0-28 21.5-46 48-46s48 18 48 46z")
                    ])
        end
                ])
    end
end
end
