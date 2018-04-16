require "../spec_helper"

describe Salt::Mime do
  describe "#loopup" do
    it "should matchs if is full filename" do
      Salt::Mime.lookup("file.zip").should eq "application/zip"
    end

    it "should matchs if is extension with dot" do
      Salt::Mime.lookup(".zip").should eq "application/zip"
    end

    it "should matchs if is only extension" do
      Salt::Mime.lookup("zip").should eq "application/zip"
    end

    it "should matchs if is path" do
      Salt::Mime.lookup("download/file.zip").should eq "application/zip"
    end

    it "should returns nil if not exists" do
      Salt::Mime.lookup("download/.fake").should be_nil
    end

    it "use default type if not exists" do
      default_type = "application/octet-stream"
      Salt::Mime.lookup(".fake", default_type).should eq default_type
    end
  end

  describe "#content_type" do
    it "should returns if matched" do
      Salt::Mime.content_type("html").should eq "text/html, charset=utf-8"
      Salt::Mime.content_type(".txt", "GBK-2312").should eq "text/plain, charset=gbk-2312"
      Salt::Mime.content_type("config/database.xml", "unknown").should eq "application/xml, charset=unknown"
    end

    it "should returns nil if not matched" do
      Salt::Mime.content_type("foobar").should be_nil
    end
  end

  describe "#extension" do
    it "should returns if matched" do
      Salt::Mime.extension("application/zip").should eq "zip"
    end

    it "should returns nil if not matched" do
      Salt::Mime.extension("application/unknown").should be_nil
    end
  end

  describe "#charset" do
    it "should returns if matched" do
      Salt::Mime.charset("text/html, charset=utf-8").should eq "utf-8"
      Salt::Mime.charset("text/html, charset = iso-8859-1").should eq "iso-8859-1"
      Salt::Mime.charset("application/tei+xml, charset=gbk-2312").should eq "gbk-2312"
    end

    it "should default charset if not matched" do
      Salt::Mime.charset("text/html").should eq "utf-8"
      Salt::Mime.charset("text/html, charset=    ").should eq "utf-8"
      Salt::Mime.charset("text/html, charset=").should eq "utf-8"
    end
  end
end
