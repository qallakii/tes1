require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "renders a word icon for docx files" do
    file = Struct.new(:filename).new(ActiveStorage::Filename.new("proposal.docx"))

    icon = file_icon_tag(file)

    assert_includes icon, 'title="DOC file"'
    assert_includes icon, "is-word"
  end

  test "renders a pdf icon for pdf files" do
    file = Struct.new(:filename).new(ActiveStorage::Filename.new("resume.pdf"))

    icon = file_icon_tag(file)

    assert_includes icon, 'title="PDF file"'
    assert_includes icon, "is-pdf"
  end

  test "renders a video icon for mp4 files" do
    file = Struct.new(:filename).new(ActiveStorage::Filename.new("demo.mp4"))

    icon = file_icon_tag(file)

    assert_includes icon, 'title="MP4 file"'
    assert_includes icon, "is-video"
  end

  test "renders an executable icon for exe files" do
    file = Struct.new(:filename).new(ActiveStorage::Filename.new("installer.exe"))

    icon = file_icon_tag(file)

    assert_includes icon, 'title="EXE file"'
    assert_includes icon, "is-executable"
  end
end
