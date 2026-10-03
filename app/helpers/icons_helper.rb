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
end
