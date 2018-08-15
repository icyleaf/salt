require "../spec_helper"

private def mock_enviroment(method = "GET",
                            resource = "/",
                            headers : HTTP::Headers? = nil,
                            body : String? = nil)
  io = IO::Memory.new
  request = HTTP::Request.new(method, resource, headers, body)
  response = HTTP::Server::Response.new(io)
  context = HTTP::Server::Context.new(request, response)
  Salt::Environment.new(context)
end

describe Salt::Environment do
  describe "with initialize" do
    it "should gets version and headers" do
      env = mock_enviroment
      env.version.should eq "HTTP/1.1"
      env.headers.size.should eq 0
    end
  end

  describe "with uri" do
    it "should gets http uri" do
      env = mock_enviroment("GET", "/path/to?name=foo", HTTP::Headers{"Host" => "example.com"})
      env.url.should eq "http://example.com/path/to?name=foo"
      env.scheme.should eq "http"
      env.base_url.should eq "http://example.com"
      env.host.should eq "example.com"
      env.host_with_port.should eq "example.com"
      env.port.should eq 80
      env.path.should eq "/path/to"
      env.full_path.should eq "/path/to?name=foo"
    end

    it "should gets http uri without HOST" do
      env = mock_enviroment("GET", "/path/to?name=foo")
      env.url.should eq "/path/to?name=foo"
      env.scheme.should eq "http"
      env.base_url.should eq nil
      env.host.should eq nil
      env.host_with_port.should eq nil
      env.port.should eq 80
      env.path.should eq "/path/to"
      env.full_path.should eq "/path/to?name=foo"
    end
  end

  describe "with methods" do
    {% for name in Salt::Environment::Methods::NAMES %}
      it "should gets {{ name.id }} method" do
        env = mock_enviroment({{ name.id.stringify }})
        env.method.should eq {{ name.id.stringify }}
        env.{{ name.id.downcase }}?.should be_true
      end
    {% end %}
  end

  describe "with parameters" do
    it "should gets query params" do
      env = mock_enviroment("GET", "/path/to?name=foo#toc")
      env.form_data?.should be_false
      env.query_params["name"].should eq "foo"
      env.params["name"].should eq "foo"
    end

    it "should gets form urlencoded body params" do
      env = mock_enviroment("POST", "/path/to", HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"}, "name=foo")
      env.form_data?.should be_false
      env.params["name"].should eq "foo"
    end

    it "should gets form data body params" do
      io = IO::Memory.new
      builder = HTTP::FormData::Builder.new(io)
      builder.field("name", "foo")
      builder.finish

      env = mock_enviroment("POST", "/path/to", HTTP::Headers{"Content-Type" => builder.content_type}, io.to_s)
      env.form_data?.should be_true
      env.params["name"].should eq "foo"
    end

    it "should gets files" do
      io = IO::Memory.new
      builder = HTTP::FormData::Builder.new(io)
      builder.field("name", "foo")
      builder.file("not_file", IO::Memory.new("hello"))
      builder.file("file", File.open("shard.yml"), HTTP::FormData::FileMetadata.new(filename: "shard.yml"))
      builder.finish

      env = mock_enviroment("POST", "/path/to", HTTP::Headers{"Content-Type" => builder.content_type}, io.to_s)
      env.form_data?.should be_true
      env.files["file"].filename.should eq "shard.yml"
      File.open(env.files["file"].tempfile.path).gets_to_end.should eq File.open("shard.yml").gets_to_end
      expect_raises KeyError do
        env.files["not_file"]
      end
      env.files["not_file"]?.should be_nil

      env.params["not_file"].should eq "hello"
      env.params["name"].should eq "foo"
    end
  end
end
