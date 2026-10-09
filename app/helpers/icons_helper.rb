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

  PLUS_ICON_PATH = "M388,1053 L378,1053 L378,1063 C378,1064.1 377.104,1065 376,1065 C374.896,1065 374,1064.1 374,1063 L374,1053 L364,1053 C362.896,1053 362,1052.1 362,1051 C362,1049.9 362.896,1049 364,1049 L374,1049 L374,1039 C374,1037.9 374.896,1037 376,1037 C377.104,1037 378,1037.9 378,1039 L378,1049 L388,1049 C389.104,1049 390,1049.9 390,1051 C390,1052.1 389.104,1053 388,1053 L388,1053 Z M388,1047 L380,1047 L380,1039 C380,1036.79 378.209,1035 376,1035 C373.791,1035 372,1036.79 372,1039 L372,1047 L364,1047 C361.791,1047 360,1048.79 360,1051 C360,1053.21 361.791,1055 364,1055 L372,1055 L372,1063 C372,1065.21 373.791,1067 376,1067 C378.209,1067 380,1065.21 380,1063 L380,1055 L388,1055 C390.209,1055 392,1053.21 392,1051 C392,1048.79 390.209,1047 388,1047 L388,1047 Z"

  def plus_icon(width: 0, height: 0, color: "currentColor")
    content_tag(:svg,
                tag.path(d: PLUS_ICON_PATH, fill: color),
                xmlns: "http://www.w3.org/2000/svg", viewBox: "360 1035 32 32",
                fill: "none", preserveAspectRatio: "xMidYMid meet",
                width: width, height: height,
                aria: { label: "plus-icon" }
               )
  end

  FOLDER_OPEN_ICON_PATH = "M1 5C1 3.34315 2.34315 2 4 2H8.55848C9.84977 2 10.9962 2.82629 11.4045 4.05132L11.7208 5H20C21.1046 5 22 5.89543 22 7V9.00961C23.1475 9.12163 23.9808 10.196 23.7695 11.3578L22.1332 20.3578C21.9603 21.3087 21.132 22 20.1654 22H3C1.89543 22 1 21.1046 1 20V5ZM20 9V7H11.7208C10.8599 7 10.0956 6.44914 9.82339 5.63246L9.50716 4.68377C9.37105 4.27543 8.98891 4 8.55848 4H4C3.44772 4 3 4.44772 3 5V12.2709L3.35429 10.588C3.54913 9.66249 4.36562 9 5.31139 9H20ZM3.36634 20C3.41777 19.9109 3.4562 19.8122 3.47855 19.706L5.31139 11L21 11H21.8018L20.1654 20L3.36634 20Z".freeze

  def folder_open_icon(width: 24, height: 24, color: "currentColor", label: "View")
    content_tag(:svg,
                tag.path(d: FOLDER_OPEN_ICON_PATH, fill: color),
                xmlns: "http://www.w3.org/2000/svg",
                viewBox: "0 0 20 14",
                fill: "none",
                preserveAspectRatio: "xMidYMid meet",
                width: width,
                height: height,
                role: "img",
                aria: { label: label })
  end

  FOLDER_CLOSED_ICON_PATH = "M1 5C1 3.34315 2.34315 2 4 2H8.55848C9.84977 2 10.9962 2.82629 11.4045 4.05132L11.7208 5H20C21.1046 5 22 5.89543 22 7V20C22 21.1046 21.1046 22 20 22H3C1.89543 22 1 21.1046 1 20V5ZM3 5C3 4.44772 3.44772 4 4 4H8.55848C8.98891 4 9.37105 4.27543 9.50716 4.68377L9.82339 5.63246C10.0956 6.44914 10.8599 7 11.7208 7H20V20H3V5Z".freeze

  def folder_closed_icon(width: 24, height: 24, color: "currentColor", label: "View")
    content_tag(:svg,
                tag.path(d: FOLDER_CLOSED_ICON_PATH, fill: color),
                xmlns: "http://www.w3.org/2000/svg",
                viewBox: "0 0 20 14",
                fill: "none",
                preserveAspectRatio: "xMidYMid meet",
                width: width,
                height: height,
                role: "img",
                aria: { label: label })
  end

  FILE_ICON_PATH = "M7 2H14L20 8V19C20 20.6569 18.6569 22 17 22H7C5.34315 22 4 20.6569 4 19V5C4 3.34315 5.34315 2 7 2ZM7 4H13.1716L18 8.8284V19C18 19.5523 17.5523 20 17 20H7C6.44772 20 6 19.5523 6 19V5C6 4.44772 6.44772 4 7 4ZM8 11H16V13H8V11ZM8 15H14V17H8V15Z".freeze

  def file_icon(width: 24, height: 24, color: "currentColor", label: "View")
    content_tag(:svg,
                tag.path(d: FILE_ICON_PATH, fill: color),
                xmlns: "http://www.w3.org/2000/svg",
                viewBox: "0 0 20 14",
                fill: "none",
                preserveAspectRatio: "xMidYMid meet",
                width: width,
                height: height,
                role: "img",
                aria: { label: label })
  end

  NEW_FILE_ICON_PATH = [ "M191.344,20.922l-95.155,95.155c-0.756,0.756-1.297,1.699-1.565,2.734l-8.167,31.454c-0.534,2.059,0.061,4.246,1.565,5.751 c1.14,1.139,2.671,1.757,4.242,1.757c0.503,0,1.009-0.063,1.508-0.192l31.454-8.168c1.035-0.269,1.979-0.81,2.734-1.565 l95.153-95.153c0.002-0.002,0.004-0.003,0.005-0.004s0.003-0.004,0.004-0.005l19.156-19.156c2.344-2.343,2.344-6.142,0.001-8.484 L218.994,1.758C217.868,0.632,216.343,0,214.751,0c-1.591,0-3.117,0.632-4.242,1.758l-19.155,19.155 c-0.002,0.002-0.004,0.003-0.005,0.004S191.346,20.921,191.344,20.922z M120.631,138.208l-19.993,5.192l5.191-19.993l89.762-89.762 l14.801,14.802L120.631,138.208z M214.751,14.485l14.801,14.802l-10.675,10.675L204.076,25.16L214.751,14.485z",
   "M238.037,65.022c-3.313,0-6,2.687-6,6v192.813H43.799V34.417h111.063c3.313,0,6-2.687,6-6s-2.687-6-6-6H37.799 c-3.313,0-6,2.687-6,6v241.419c0,3.313,2.687,6,6,6h200.238c3.313,0,6-2.687,6-6V71.022 C244.037,67.709,241.351,65.022,238.037,65.022z" ].join(" ").freeze

  def new_file_icon(width: 24, height: 24, color: "currentColor", label: "New file")
    content_tag(:svg,
                tag.path(d: NEW_FILE_ICON_PATH, fill: color),
                xmlns: "http://www.w3.org/2000/svg",
                viewBox: "0 0 276 276",
                fill: "none",
                preserveAspectRatio: "xMidYMid meet",
                width: width,
                height: height,
                role: "img",
                aria: { label: label })
  end

  CLOUD_SAVE_ICON_PATH = [ "M9 13.2222L10.8462 15L15 11M8.4 19C5.41766 19 3 16.6044 3 13.6493C3 11.2001 4.8 8.9375 7.5 8.5C8.34694 6.48637 10.3514 5 12.6893 5C15.684 5 18.1317 7.32251 18.3 10.25C19.8893 10.9449 21 12.6503 21 14.4969C21 16.9839 18.9853 19 16.5 19L8.4 19Z" ].join(" ").freeze

  def cloud_save_icon(width: 24, height: 24, color: "currentColor", label: "View")
    content_tag(:svg,
                tag.path(d: CLOUD_SAVE_ICON_PATH, fill: color),
                xmlns: "http://www.w3.org/2000/svg",
                viewBox: "0 0 20 14",
                fill: "none",
                preserveAspectRatio: "xMidYMid meet",
                width: width,
                height: height,
                role: "img",
                aria: { label: label })
  end

  VIEW_ICON_PATH = "M 2.06943 7.14746C 2.04023 7.08008 2.02279 7.03156 2.0125 7C 2.02279 6.96844 2.04023 6.91992 2.06943 6.85254C 2.15181 6.65991 2.2622 6.45642 2.43916 6.18579C 2.80449 5.62134 3.30807 5.00348 4.01971 4.36969C 5.46653 3.06451 7.38721 1.96802 10 2C 12.6128 1.96802 14.5335 3.06451 15.9803 4.36969C 16.6919 5.00348 17.1955 5.62134 17.5608 6.18579C 17.7378 6.45642 17.8482 6.65991 17.9306 6.85254C 17.9598 6.91992 17.9772 6.96844 17.9875 7C 17.9772 7.03156 17.9598 7.08008 17.9306 7.14746C 17.8482 7.34009 17.7378 7.54358 17.5608 7.81421C 17.1955 8.37866 16.6919 8.99652 15.9803 9.63031C 14.5335 10.9355 12.6128 12.032 10 12C 7.38721 12.032 5.46653 10.9355 4.01971 9.63031C 3.30807 8.99652 2.80449 8.37866 2.43916 7.81421C 2.2622 7.54358 2.15181 7.34009 2.06943 7.14746ZM 10 0C 6.88552 0.0319824 4.3062 1.43549 2.68483 2.88031C 1.86238 3.62152 1.18983 4.44116 0.762543 5.09546C 0.543196 5.4342 0.353159 5.7854 0.234196 6.05762C 0.120506 6.32007 0 6.66284 0 7C 0 7.33716 0.120506 7.67993 0.234196 7.94238C 0.353159 8.2146 0.543196 8.5658 0.762543 8.90454C 1.18983 9.55884 1.86238 10.3785 2.68483 11.1197C 4.3062 12.5645 6.88552 13.968 10 14C 13.1145 13.968 15.6938 12.5645 17.3152 11.1197C 18.1376 10.3785 18.8102 9.55884 19.2375 8.90454C 19.4568 8.5658 19.6468 8.2146 19.7658 7.94238C 19.8795 7.67993 20 7.33716 20 7C 20 6.66284 19.8795 6.32007 19.7658 6.05762C 19.6468 5.7854 19.4568 5.4342 19.2375 5.09546C 18.8102 4.44116 18.1376 3.62152 17.3152 2.88031C 15.6938 1.43549 13.1145 0.0319824 10 0ZM 12.5 6.5C 12.6546 6.5 12.8051 6.48248 12.9496 6.44928C 12.9827 6.62781 13 6.81189 13 7C 13 8.65686 11.6569 10 10 10C 8.34315 10 7 8.65686 7 7C 7 5.34314 8.34315 4 10 4C 10.1881 4 10.3722 4.01727 10.5507 4.05042C 10.5175 4.19495 10.5 4.3454 10.5 4.5C 10.5 5.60455 11.3954 6.5 12.5 6.5Z".freeze

  def view_icon(width: 24, height: 24, color: "currentColor", label: "View")
    content_tag(:svg,
                tag.path(d: VIEW_ICON_PATH, fill: color),
                xmlns: "http://www.w3.org/2000/svg",
                viewBox: "0 0 20 14",
                fill: "none",
                preserveAspectRatio: "xMidYMid meet",
                width: width,
                height: height,
                role: "img",
                aria: { label: label })
  end

  EDIT_ICON_PATH = "M11.878,8.479c0.132,-0.242 0.346,-0.479 0.622,-0.479l1.5,0c0.552,0 1,0.448 1,1c0,0.552 -0.448,1 -1,1l-1,0c-0.552,0 -1,0.448 -1,1l0,10c0,0.552 0.448,1 1,1l1,0c0.552,0 1,0.448 1,1c0,0.552 -0.448,1 -1,1l-1.5,0c-0.276,0 -0.49,-0.237 -0.622,-0.48c-0.17,-0.31 -0.499,-0.52 -0.878,-0.52c-0.379,0 -0.708,0.21 -0.878,0.52c-0.132,0.243 -0.346,0.48 -0.622,0.48l-1.5,0c-0.552,0 -1,-0.448 -1,-1c0,-0.552 0.448,-1 1,-1l1,0c0.552,0 1,-0.448 1,-1l0,-10c0,-0.552 -0.448,-1 -1,-1l-1,0c-0.552,0 -1,-0.448 -1,-1c0,-0.552 0.448,-1 1,-1l1.5,0c0.276,0 0.49,0.237 0.622,0.479c0.17,0.311 0.499,0.521 0.878,0.521c0.379,0 0.708,-0.21 0.878,-0.521Zm-3.878,17.521c-0.552,0 -1,0.448 -1,1c0,0.552 0.448,1 1,1l16,0c0.552,0 1,-0.448 1,-1c0,-0.552 -0.448,-1 -1,-1l-16,0Z".freeze

  def edit_icon(width: 24, height: 24, color: "currentColor", label: "Edit")
    content_tag(:svg,
                tag.path(d: EDIT_ICON_PATH, fill: color),
                xmlns: "http://www.w3.org/2000/svg",
                viewBox: "7 8 18 20",
                fill: "none",
                preserveAspectRatio: "xMidYMid meet",
                width: width,
                height: height,
                role: "img",
                aria: { label: label })
  end

  DELETE_ICON_PATH = [
    "M8.391 12.32c-.636-.131-1.248.368-1.213 1.016.808 14.714 1.271 14.711 7.681 14.669C15.22 28.003 15.6 28 16 28s.78.003 1.141.005c6.41.042 6.873.045 7.681-14.669.035-.648-.577-1.147-1.212-1.016a.975.975 0 0 0-.784.896c-.17 3.094-.323 5.51-.519 7.407-.266 2.584-.588 3.883-.95 4.566-.225.426-.422.586-1.067.701-.716.128-1.615.123-3.019.115h-.002a161.358 161.358 0 0 0-2.538 0h-.001c-1.405.008-2.304.013-3.02-.115-.645-.115-.842-.275-1.067-.701-.362-.683-.684-1.982-.95-4.566-.196-1.897-.349-4.313-.519-7.407a.975.975 0 0 0-.783-.896z",
  "M6 10a1 1 0 0 1 1-1h18a1 1 0 0 1 0 2H7a1 1 0 0 1-1-1z",
  "M12.25 7.973C12.112 8.185 12 8.5 12 9h-2c0-.81.186-1.525.576-2.121.366-.536.963-1.006 1.525-1.271C13.24 5.087 14.687 5 16 5c1.313 0 2.76.087 3.899.608.562.265 1.158.735 1.525 1.271C21.814 7.475 22 8.19 22 9h-2c0-.5-.112-.815-.25-1.027-.161-.272-.324-.388-.684-.546C18.36 7.103 17.306 7 16 7c-1.306 0-2.36.103-3.066.427-.36.158-.523.274-.684.546z",
  "M12.044 14.086a1 1 0 1 1 1.998-.087l.349 7.992a1 1 0 0 1-1.998.087l-.349-7.992zM17.956 13.999a1 1 0 0 1 1.998.087l-.348 7.993a1 1 0 0 1-1.999-.088l.349-7.992z"
  ].join(" ").freeze

  def delete_icon(width: 24, height: 24, color: "currentColor", label: "Delete")
    content_tag(:svg,
                tag.path(d: DELETE_ICON_PATH, fill: color, "fill-rule": "evenodd", "clip-rule": "evenodd"),
                xmlns: "http://www.w3.org/2000/svg",
                viewBox: "6 5 20 23",
                fill: "none",
                preserveAspectRatio: "xMidYMid meet",
                width: width,
                height: height,
                role: "img",
                aria: { label: label })
  end

  def info_icon(width: 24, height: 24, color: "currentColor", label: "Info")
    content_tag(:svg,
                xmlns: "http://www.w3.org/2000/svg",
                viewBox: "0 0 24 24",
                fill: "none",
                stroke: color,
                "stroke-width": "2",
                "stroke-linecap": "round",
                "stroke-linejoin": "round",
                width: width,
                height: height,
                role: "img",
                aria: { label: label }) do
      safe_join([
                  tag.circle(cx: 12, cy: 12, r: 10),
        tag.path(d: "M12 16v-4"),
        tag.path(d: "M12 8h.01")
                ])
    end
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

  def workspaces_icon(width: 24, height: 24, color: "currentColor", label: "Workspaces")
    content_tag(:svg,
                safe_join([
                            tag.path(d: "M12 3l9 5-9 5-9-5z"),
                            tag.path(d: "M3 13l9 5 9-5")
                          ]),
                xmlns: "http://www.w3.org/2000/svg",
                viewBox: "0 0 24 24",
                fill: "none", stroke: color, "stroke-width": 2,
                "stroke-linecap": "round", "stroke-linejoin": "round",
                preserveAspectRatio: "xMidYMid meet",
                width: width, height: height,
                role: "img", aria: { label: label })
end

  def folders_icon(width: 24, height: 24, color: "currentColor", label: "Folders and pages")
    content_tag(:svg,
                tag.path(d: "M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"),
                xmlns: "http://www.w3.org/2000/svg",
                viewBox: "0 0 24 24",
                fill: "none", stroke: color, "stroke-width": 2,
                "stroke-linecap": "round", "stroke-linejoin": "round",
                preserveAspectRatio: "xMidYMid meet",
                width: width, height: height,
                role: "img", aria: { label: label })
  end

  def preview_icon(width: 24, height: 24, color: "currentColor", label: "Live preview")
    content_tag(:svg,
                safe_join([
                            tag.rect(x: 3, y: 4, width: 18, height: 16, rx: 2),
                            tag.path(d: "M12 4v16")
                          ]),
                xmlns: "http://www.w3.org/2000/svg",
                viewBox: "0 0 24 24",
                fill: "none", stroke: color, "stroke-width": 2,
                "stroke-linecap": "round", "stroke-linejoin": "round",
                preserveAspectRatio: "xMidYMid meet",
                width: width, height: height,
                role: "img", aria: { label: label })
  end

  def autosave_icon(width: 24, height: 24, color: "currentColor", label: "Autosave")
    content_tag(:svg,
                tag.path(d: "M20 6L9 17l-5-5"),
                xmlns: "http://www.w3.org/2000/svg",
                viewBox: "0 0 24 24",
                fill: "none", stroke: color, "stroke-width": 2,
                "stroke-linecap": "round", "stroke-linejoin": "round",
                preserveAspectRatio: "xMidYMid meet",
                width: width, height: height,
                role: "img", aria: { label: label })
  end

  def storage_icon(width: 24, height: 24, color: "currentColor", label: "Storage")
    content_tag(:svg,
                safe_join([
                            tag.ellipse(cx: 12, cy: 6, rx: 8, ry: 3),
                            tag.path(d: "M4 6v6c0 1.7 3.6 3 8 3s8-1.3 8-3V6M4 12v6c0 1.7 3.6 3 8 3s8-1.3 8-3v-6")
                          ]),
                xmlns: "http://www.w3.org/2000/svg",
                viewBox: "0 0 24 24",
                fill: "none", stroke: color, "stroke-width": 2,
                "stroke-linecap": "round", "stroke-linejoin": "round",
                preserveAspectRatio: "xMidYMid meet",
                width: width, height: height,
                role: "img", aria: { label: label })
  end

  def shield_icon(width: 24, height: 24, color: "currentColor", label: "Security")
    content_tag(:svg,
                tag.path(d: "M12 3l8 3v6c0 4.5-3.2 8-8 9-4.8-1-8-4.5-8-9V6z"),
                xmlns: "http://www.w3.org/2000/svg",
                viewBox: "0 0 24 24",
                fill: "none", stroke: color, "stroke-width": 2,
                "stroke-linecap": "round", "stroke-linejoin": "round",
                preserveAspectRatio: "xMidYMid meet",
                width: width, height: height,
                role: "img", aria: { label: label })
  end
end
