module ApplicationHelper
  FILE_ICON_GROUPS = {
    word: %w[doc docx odt],
    pdf: %w[pdf],
    sheet: %w[xls xlsx csv tsv ods],
    slide: %w[ppt pptx odp key],
    image: %w[jpg jpeg png gif webp svg bmp tif tiff heic avif],
    video: %w[mp4 m4v mov avi mkv webm mpg mpeg],
    audio: %w[mp3 wav ogg aac flac m4a],
    archive: %w[zip rar 7z tar gz bz2 xz],
    executable: %w[exe msi dmg pkg app bat cmd sh deb rpm apk],
    text: %w[txt md log json xml yml yaml html css js ts tsx jsx rb py java c cpp h hpp]
  }.freeze

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def format_bytes(bytes)
    value = bytes.to_i
    units = %w[B KB MB GB TB]
    unit_index = 0

    while value >= 1024 && unit_index < units.length - 1
      value /= 1024.0
      unit_index += 1
    end

    unit_index.zero? ? "#{value.to_i} #{units[unit_index]}" : "#{format('%.1f', value)} #{units[unit_index]}"
  end

  def folder_icon_tag(css_class: "folder-icon", size: 22)
    content_tag(
      :span,
      class: css_class,
      aria: { hidden: true },
      title: "Folder"
    ) do
      svg_icon_tag(size, "folder-icon-svg") do
        safe_join(
          [
            tag.path(
              d: "M3.6 7.5a2 2 0 0 1 2-2h4.6l1.7 1.8h6.8a2 2 0 0 1 2 2v1.2H3.6z",
              fill: "#fde68a",
              "stroke-linejoin" => "round"
            ),
            tag.path(
              d: "M2.9 9.2A2 2 0 0 1 4.9 7.2h14.2a2 2 0 0 1 2 2v8.1a2 2 0 0 1-2 2H4.9a2 2 0 0 1-2-2z",
              fill: "#fbbf24",
              stroke: "#d97706",
              "stroke-width" => "1.0",
              "stroke-linejoin" => "round"
            )
          ]
        )
      end
    end
  end

  def file_icon_tag(file, content_type: nil, css_class: "file-icon", size: 22)
    family, title_label, icon_label = file_icon_details(file, content_type: content_type)

    content_tag(
      :span,
      class: [css_class, "is-#{family}"].join(" "),
      aria: { hidden: true },
      title: "#{title_label} file"
    ) do
      svg_icon_tag(size, "file-icon-svg") do
        safe_join(file_icon_nodes(family, icon_label))
      end
    end
  end

  private

  def svg_icon_tag(size, css_class)
    content_tag(
      :svg,
      class: css_class,
      viewBox: "0 0 24 24",
      width: size,
      height: size,
      fill: "none",
      xmlns: "http://www.w3.org/2000/svg"
    ) do
      yield
    end
  end

  def file_icon_details(file, content_type: nil)
    extension = file_extension_for(file)
    family = file_icon_family_for(extension, content_type)
    title_label = file_icon_title_label_for(extension, family)
    [family, title_label, file_icon_glyph_for(family, title_label)]
  end

  def file_extension_for(file)
    return "" unless file.respond_to?(:filename)

    file.filename.extension.to_s.downcase
  end

  def file_icon_family_for(extension, content_type)
    content = content_type.to_s.downcase

    return :word if FILE_ICON_GROUPS[:word].include?(extension) || content.include?("msword") || content.include?("wordprocessingml")
    return :pdf if FILE_ICON_GROUPS[:pdf].include?(extension) || content.include?("pdf")
    return :sheet if FILE_ICON_GROUPS[:sheet].include?(extension) || content.include?("ms-excel") || content.include?("spreadsheetml") || content.include?("csv")
    return :slide if FILE_ICON_GROUPS[:slide].include?(extension) || content.include?("ms-powerpoint") || content.include?("presentationml")
    return :image if FILE_ICON_GROUPS[:image].include?(extension) || content.start_with?("image/")
    return :video if FILE_ICON_GROUPS[:video].include?(extension) || content.start_with?("video/")
    return :audio if FILE_ICON_GROUPS[:audio].include?(extension) || content.start_with?("audio/")
    return :archive if FILE_ICON_GROUPS[:archive].include?(extension) || content.include?("zip") || content.include?("compressed") || content.include?("archive")
    return :executable if FILE_ICON_GROUPS[:executable].include?(extension) || content.include?("x-msdownload") || content.include?("x-executable")
    return :text if FILE_ICON_GROUPS[:text].include?(extension) || content.start_with?("text/")

    :generic
  end

  def file_icon_title_label_for(extension, family)
    case family
    when :word
      "DOC"
    when :pdf
      "PDF"
    when :sheet
      %w[csv tsv].include?(extension) ? extension.upcase : "XLS"
    when :slide
      "PPT"
    when :image
      compact_extension_label(extension, fallback: "IMG")
    when :video
      compact_extension_label(extension, fallback: "MP4")
    when :audio
      compact_extension_label(extension, fallback: "MP3")
    when :archive
      compact_extension_label(extension, fallback: "ZIP")
    when :executable
      compact_extension_label(extension, fallback: "EXE")
    when :text
      compact_extension_label(extension, fallback: "TXT")
    else
      compact_extension_label(extension, fallback: "FILE")
    end
  end

  def file_icon_glyph_for(family, title_label)
    case family
    when :word
      "W"
    when :sheet
      "X"
    when :slide
      "P"
    when :pdf
      "PDF"
    when :text
      title_label.length <= 3 ? title_label : "TXT"
    else
      title_label
    end
  end

  def file_icon_nodes(family, icon_label)
    case family
    when :word
      word_file_icon_nodes
    when :pdf
      pdf_file_icon_nodes(icon_label)
    when :sheet
      sheet_file_icon_nodes
    when :slide
      slide_file_icon_nodes
    when :image
      image_file_icon_nodes
    when :video
      video_file_icon_nodes
    when :audio
      audio_file_icon_nodes
    when :archive
      archive_file_icon_nodes
    when :executable
      executable_file_icon_nodes
    when :text
      text_file_icon_nodes(icon_label)
    else
      generic_file_icon_nodes
    end
  end

  def word_file_icon_nodes
    file_page_shell_nodes + [
      tag.rect(x: "4.2", y: "3.6", width: "7.2", height: "16.8", rx: "1.15", fill: "currentColor"),
      icon_label_text("W", x: 7.8, y: 13.3, size: 7.0)
    ] + file_page_line_nodes
  end

  def pdf_file_icon_nodes(icon_label)
    [
      tag.path(
        d: "M7.4 2.8h7l4.2 4.1v12.4a1.8 1.8 0 0 1-1.8 1.8H7.4a1.8 1.8 0 0 1-1.8-1.8V4.6a1.8 1.8 0 0 1 1.8-1.8z",
        fill: "currentColor",
        stroke: "rgba(127,29,29,0.16)",
        "stroke-width" => "1.0",
        "stroke-linejoin" => "round"
      ),
      tag.path(
        d: "M14.4 2.8v4.1h4.2",
        fill: "rgba(255,255,255,0.24)",
        stroke: "rgba(255,255,255,0.28)",
        "stroke-width" => "0.9",
        "stroke-linejoin" => "round"
      ),
      tag.path(
        d: "M9.1 11.2c1-1.5 2-3.2 2.8-5 .8 1.7 1.8 3.3 3 4.8-1.3.4-2.6.5-3.8.2 1.2-.5 2.3-1.3 3.4-2.5-1.2 1.6-2.2 3-3 4.2",
        stroke: "#ffffff",
        "stroke-width" => "0.95",
        "stroke-linecap" => "round",
        "stroke-linejoin" => "round",
        opacity: "0.92"
      ),
      tag.rect(x: "6.1", y: "14.5", width: "11.8", height: "4.2", rx: "1.05", fill: "rgba(255,255,255,0.18)"),
      icon_label_text(icon_label, x: 12.0, y: 17.55, size: 4.0)
    ]
  end

  def sheet_file_icon_nodes
    file_page_shell_nodes + [
      tag.rect(x: "4.2", y: "3.6", width: "7.2", height: "16.8", rx: "1.15", fill: "currentColor"),
      icon_label_text("X", x: 7.8, y: 13.35, size: 7.0),
      detail_line("M13.1 8.8h4.4"),
      detail_line("M13.1 11.2h4.4"),
      detail_line("M13.1 13.6h4.4"),
      detail_line("M14.9 8.1v6.2"),
      detail_line("M16.7 8.1v6.2")
    ]
  end

  def slide_file_icon_nodes
    file_page_shell_nodes + [
      tag.rect(x: "4.2", y: "3.6", width: "7.2", height: "16.8", rx: "1.15", fill: "currentColor"),
      icon_label_text("P", x: 7.8, y: 13.35, size: 7.0),
      tag.rect(
        x: "12.7",
        y: "8.6",
        width: "4.8",
        height: "3.8",
        rx: "0.75",
        fill: "currentColor",
        opacity: "0.14",
        stroke: "currentColor",
        "stroke-width" => "1.05"
      ),
      detail_line("M12.8 14.4h4.8"),
      detail_line("M15.2 12.5v1.6")
    ]
  end

  def image_file_icon_nodes
    [
      tag.rect(
        x: "3.5",
        y: "4.4",
        width: "17.0",
        height: "14.8",
        rx: "2.4",
        fill: "#ffffff",
        stroke: "currentColor",
        "stroke-width" => "1.3"
      ),
      tag.rect(
        x: "5.0",
        y: "5.9",
        width: "14.0",
        height: "11.8",
        rx: "1.6",
        fill: "currentColor",
        opacity: "0.12"
      ),
      tag.circle(cx: "8.9", cy: "9.2", r: "1.2", fill: "currentColor"),
      tag.path(
        d: "M6.3 15.6l3.1-3.3 2.4 2.5 2.1-1.9 3.1 2.7",
        stroke: "currentColor",
        "stroke-width" => "1.4",
        "stroke-linecap" => "round",
        "stroke-linejoin" => "round"
      )
    ]
  end

  def video_file_icon_nodes
    [
      tag.rect(
        x: "3.5",
        y: "5.0",
        width: "17.0",
        height: "12.8",
        rx: "2.5",
        fill: "#ffffff",
        stroke: "currentColor",
        "stroke-width" => "1.3"
      ),
      tag.rect(x: "5.0", y: "6.5", width: "14.0", height: "9.8", rx: "1.7", fill: "currentColor", opacity: "0.12"),
      tag.path(d: "M10.1 9.2l5.2 3.2-5.2 3.2z", fill: "currentColor"),
      tag.path(
        d: "M8.0 18.8h8.0",
        stroke: "currentColor",
        "stroke-width" => "1.2",
        "stroke-linecap" => "round"
      )
    ]
  end

  def audio_file_icon_nodes
    [
      tag.circle(
        cx: "12",
        cy: "12",
        r: "8.0",
        fill: "#ffffff",
        stroke: "currentColor",
        "stroke-width" => "1.3"
      ),
      tag.circle(cx: "12", cy: "12", r: "6.1", fill: "currentColor", opacity: "0.12"),
      tag.path(
        d: "M10.2 8.5v5.9a1.8 1.8 0 1 1-1.3-1.7c.5 0 .9.1 1.3.4V9.5l4.2-1v4.2a1.8 1.8 0 1 1-1.3-1.7c.5 0 .9.1 1.3.4",
        stroke: "currentColor",
        "stroke-width" => "1.35",
        "stroke-linecap" => "round",
        "stroke-linejoin" => "round"
      )
    ]
  end

  def archive_file_icon_nodes
    [
      tag.rect(
        x: "4.4",
        y: "6.2",
        width: "15.2",
        height: "13.1",
        rx: "2.0",
        fill: "#ffffff",
        stroke: "currentColor",
        "stroke-width" => "1.3"
      ),
      tag.path(
        d: "M4.9 9.2h14.2",
        stroke: "currentColor",
        "stroke-width" => "1.2",
        "stroke-linecap" => "round"
      ),
      tag.path(
        d: "M12 7.1v10.1",
        stroke: "currentColor",
        "stroke-width" => "1.2",
        "stroke-linecap" => "round",
        opacity: "0.55"
      ),
      tag.rect(x: "11.2", y: "10.2", width: "1.6", height: "2.0", rx: "0.45", fill: "currentColor"),
      tag.rect(x: "11.2", y: "13.1", width: "1.6", height: "2.8", rx: "0.45", fill: "currentColor", opacity: "0.55")
    ]
  end

  def executable_file_icon_nodes
    [
      tag.rect(x: "3.6", y: "5.2", width: "16.8", height: "12.9", rx: "2.1", fill: "#111827"),
      tag.circle(cx: "6.5", cy: "8.1", r: "0.6", fill: "#ef4444"),
      tag.circle(cx: "8.4", cy: "8.1", r: "0.6", fill: "#f59e0b"),
      tag.circle(cx: "10.3", cy: "8.1", r: "0.6", fill: "#10b981"),
      tag.path(
        d: "M7.4 11.9l2.1 1.8-2.1 1.8",
        stroke: "#ffffff",
        "stroke-width" => "1.2",
        "stroke-linecap" => "round",
        "stroke-linejoin" => "round"
      ),
      tag.path(
        d: "M11.6 15.5h4.5",
        stroke: "#ffffff",
        "stroke-width" => "1.2",
        "stroke-linecap" => "round"
      )
    ]
  end

  def text_file_icon_nodes(icon_label)
    file_page_shell_nodes + [
      detail_line("M8.4 8.7h8.0"),
      detail_line("M8.4 10.9h8.0"),
      detail_line("M8.4 13.1h5.4"),
      tag.rect(x: "8.0", y: "15.0", width: "9.4", height: "3.7", rx: "0.95", fill: "currentColor", opacity: "0.14"),
      icon_label_text_dark(icon_label, x: 12.7, y: 17.45, size: 4.0)
    ]
  end

  def generic_file_icon_nodes
    file_page_shell_nodes + [
      detail_line("M8.6 8.9h7.8"),
      detail_line("M8.6 11.2h7.8"),
      detail_line("M8.6 13.5h5.1"),
      detail_line("M8.6 15.8h6.4")
    ]
  end

  def file_page_shell_nodes
    [
      tag.path(
        d: "M7.4 2.8h7l4.2 4.1v12.4a1.8 1.8 0 0 1-1.8 1.8H7.4a1.8 1.8 0 0 1-1.8-1.8V4.6a1.8 1.8 0 0 1 1.8-1.8z",
        fill: "#ffffff",
        stroke: "rgba(15,23,42,0.16)",
        "stroke-width" => "1.05",
        "stroke-linejoin" => "round"
      ),
      tag.path(
        d: "M14.4 2.8v4.1h4.2",
        fill: "#f8fafc",
        stroke: "rgba(15,23,42,0.12)",
        "stroke-width" => "0.95",
        "stroke-linejoin" => "round"
      )
    ]
  end

  def file_page_line_nodes
    [
      detail_line("M13.2 8.8h4.1"),
      detail_line("M13.2 11.1h4.1"),
      detail_line("M13.2 13.4h3.0")
    ]
  end

  def detail_line(path_data)
    tag.path(
      d: path_data,
      stroke: "rgba(100,116,139,0.36)",
      "stroke-width" => "1.0",
      "stroke-linecap" => "round"
    )
  end

  def icon_label_text(text, x:, y:, size:)
    content_tag(
      :text,
      text,
      x: x.to_s,
      y: y.to_s,
      class: "file-icon-label",
      "text-anchor" => "middle",
      "font-size" => size.to_s
    )
  end

  def icon_label_text_dark(text, x:, y:, size:)
    content_tag(
      :text,
      text,
      x: x.to_s,
      y: y.to_s,
      class: "file-icon-label-dark",
      "text-anchor" => "middle",
      "font-size" => size.to_s
    )
  end

  def compact_extension_label(extension, fallback:)
    value = extension.to_s.upcase
    return fallback if value.blank?
    return "JPG" if %w[JPEG JPG].include?(value)

    value[0, 3]
  end
end
