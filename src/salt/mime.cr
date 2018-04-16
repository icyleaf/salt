module Salt::Mime
  extend self

  # Lookup the MIME type for a file path/extension.
  #
  # ### Example
  #
  # ```
  # Salt::Mime.lookup("html") # => "application/html"
  # Salt::Mime.lookup(".html") # => "application/html"
  # Salt::Mime.lookup("config/database.xml") # => "application/xml"
  # Salt::Mime.lookup(".custom") # => nil
  # Salt::Mime.lookup(".custom", "text/plain") # => "text/plain"
  # ```
  def lookup(path : String, default_type : String? = nil) : String?
    return if path.empty?

    extension = ::File.extname("x.#{path}").downcase.strip('.')
    return if extension.empty?

    if !(content_type = stores.types[extension]?) && (default = default_type)
      content_type = default
    end

    content_type
  end

  # Create a full Content-Type header given a MIME type or extension.
  #
  # https://www.w3.org/TR/WD-html40-970708/charset.html
  #
  # ### Example
  #
  # ```
  # Salt::Mime.content_type("html") # => "application/html, charset=utf-8"
  # Salt::Mime.content_type(".html", "gbk-2312") # => "application/html, charset=gbk-2312"
  # Salt::Mime.content_type("config/database.xml") # => "application/xml, charset=utf-8"
  # Salt::Mime.content_type(".custom") # => nil
  # ```
  def content_type(extension : String, charset : String = DEFAULT_CHARSET) : String?
    return if extension.empty?
    return unless content_type = lookup(extension)

    "#{content_type}, charset=#{charset.downcase}"
  end

  # Get the default extension for a MIME type.
  #
  # ### Example
  #
  # ```
  # Salt::Mime.extension("application/html") # => "html"
  # ```
  def extension(content_type : String) : String?
    return if content_type.empty?

    if charset?(content_type)
      content_type = content_type.split(",", 2).first.strip
    end

    stores.extensions[content_type]?.try(&.first)
  end

  # Get the default charset for a MIME type.
  #
  # ### Example
  #
  # ```
  # Salt::Mime.charset("application/html") # => "utf-8"
  # Salt::Mime.charset("application/html, charset=gbk-2312") # => "gbk-2312"
  # ```
  def charset(content_type : String) : String
    return DEFAULT_CHARSET if content_type.empty?

    charset = DEFAULT_CHARSET
    if charset?(content_type)
      _, value = content_type.downcase.split("charset", 2)
      value = value.strip.strip('=').strip
      charset = value unless value.empty?
    end

    charset
  end

  # :nodoc:
  private def charset?(content_type : String)
    content_type.downcase.includes?("charset")
  end

  # :nodoc:
  private def stores
    @@stores ||= begin
      types = Hash(String, String).new
      extensions = Hash(String, Array(String)).new

      MIME_TYPES.each do |_type, _extensions|
        extensions[_type] ||= Array(String).new
        _extensions.each do |_extension|
          types[_extension] = _type
          extensions[_type] << _extension
        end
      end
      Mapper.new(types, extensions)
    end.as(Mapper)
  end

  # :nodoc:
  private record Mapper, types : Hash(String, String), extensions : Hash(String, Array(String))

  DEFAULT_CHARSET = "utf-8"

  # Standard MIME types
  #
  # Source: https://github.com/broofa/node-mime/blob/master/types/standard.json
  # version: v2.3.1
  MIME_TYPES = {
    "application/andrew-inset" => ["ez"],
    "application/applixware" => ["aw"],
    "application/atom+xml" => ["atom"],
    "application/atomcat+xml" => ["atomcat"],
    "application/atomsvc+xml" => ["atomsvc"],
    "application/bdoc" => ["bdoc"],
    "application/ccxml+xml" => ["ccxml"],
    "application/cdmi-capability" => ["cdmia"],
    "application/cdmi-container" => ["cdmic"],
    "application/cdmi-domain" => ["cdmid"],
    "application/cdmi-object" => ["cdmio"],
    "application/cdmi-queue" => ["cdmiq"],
    "application/cu-seeme" => ["cu"],
    "application/dash+xml" => ["mpd"],
    "application/davmount+xml" => ["davmount"],
    "application/docbook+xml" => ["dbk"],
    "application/dssc+der" => ["dssc"],
    "application/dssc+xml" => ["xdssc"],
    "application/ecmascript" => ["ecma"],
    "application/emma+xml" => ["emma"],
    "application/epub+zip" => ["epub"],
    "application/exi" => ["exi"],
    "application/font-tdpfr" => ["pfr"],
    "application/font-woff" => ["woff"],
    "application/geo+json" => ["geojson"],
    "application/gml+xml" => ["gml"],
    "application/gpx+xml" => ["gpx"],
    "application/gxf" => ["gxf"],
    "application/gzip" => ["gz"],
    "application/hjson" => ["hjson"],
    "application/hyperstudio" => ["stk"],
    "application/inkml+xml" => ["ink", "inkml"],
    "application/ipfix" => ["ipfix"],
    "application/java-archive" => ["jar", "war", "ear"],
    "application/java-serialized-object" => ["ser"],
    "application/java-vm" => ["class"],
    "application/javascript" => ["js", "mjs"],
    "application/json" => ["json", "map"],
    "application/json5" => ["json5"],
    "application/jsonml+json" => ["jsonml"],
    "application/ld+json" => ["jsonld"],
    "application/lost+xml" => ["lostxml"],
    "application/mac-binhex40" => ["hqx"],
    "application/mac-compactpro" => ["cpt"],
    "application/mads+xml" => ["mads"],
    "application/manifest+json" => ["webmanifest"],
    "application/marc" => ["mrc"],
    "application/marcxml+xml" => ["mrcx"],
    "application/mathematica" => ["ma", "nb", "mb"],
    "application/mathml+xml" => ["mathml"],
    "application/mbox" => ["mbox"],
    "application/mediaservercontrol+xml" => ["mscml"],
    "application/metalink+xml" => ["metalink"],
    "application/metalink4+xml" => ["meta4"],
    "application/mets+xml" => ["mets"],
    "application/mods+xml" => ["mods"],
    "application/mp21" => ["m21", "mp21"],
    "application/mp4" => ["mp4s", "m4p"],
    "application/msword" => ["doc", "dot"],
    "application/mxf" => ["mxf"],
    "application/octet-stream" => ["bin", "dms", "lrf", "mar", "so", "dist", "distz", "pkg", "bpk", "dump", "elc", "deploy", "exe", "dll", "deb", "dmg", "iso", "img", "msi", "msp", "msm", "buffer"],
    "application/oda" => ["oda"],
    "application/oebps-package+xml" => ["opf"],
    "application/ogg" => ["ogx"],
    "application/omdoc+xml" => ["omdoc"],
    "application/onenote" => ["onetoc", "onetoc2", "onetmp", "onepkg"],
    "application/oxps" => ["oxps"],
    "application/patch-ops-error+xml" => ["xer"],
    "application/pdf" => ["pdf"],
    "application/pgp-encrypted" => ["pgp"],
    "application/pgp-signature" => ["asc", "sig"],
    "application/pics-rules" => ["prf"],
    "application/pkcs10" => ["p10"],
    "application/pkcs7-mime" => ["p7m", "p7c"],
    "application/pkcs7-signature" => ["p7s"],
    "application/pkcs8" => ["p8"],
    "application/pkix-attr-cert" => ["ac"],
    "application/pkix-cert" => ["cer"],
    "application/pkix-crl" => ["crl"],
    "application/pkix-pkipath" => ["pkipath"],
    "application/pkixcmp" => ["pki"],
    "application/pls+xml" => ["pls"],
    "application/postscript" => ["ai", "eps", "ps"],
    "application/pskc+xml" => ["pskcxml"],
    "application/raml+yaml" => ["raml"],
    "application/rdf+xml" => ["rdf"],
    "application/reginfo+xml" => ["rif"],
    "application/relax-ng-compact-syntax" => ["rnc"],
    "application/resource-lists+xml" => ["rl"],
    "application/resource-lists-diff+xml" => ["rld"],
    "application/rls-services+xml" => ["rs"],
    "application/rpki-ghostbusters" => ["gbr"],
    "application/rpki-manifest" => ["mft"],
    "application/rpki-roa" => ["roa"],
    "application/rsd+xml" => ["rsd"],
    "application/rss+xml" => ["rss"],
    "application/rtf" => ["rtf"],
    "application/sbml+xml" => ["sbml"],
    "application/scvp-cv-request" => ["scq"],
    "application/scvp-cv-response" => ["scs"],
    "application/scvp-vp-request" => ["spq"],
    "application/scvp-vp-response" => ["spp"],
    "application/sdp" => ["sdp"],
    "application/set-payment-initiation" => ["setpay"],
    "application/set-registration-initiation" => ["setreg"],
    "application/shf+xml" => ["shf"],
    "application/smil+xml" => ["smi", "smil"],
    "application/sparql-query" => ["rq"],
    "application/sparql-results+xml" => ["srx"],
    "application/srgs" => ["gram"],
    "application/srgs+xml" => ["grxml"],
    "application/sru+xml" => ["sru"],
    "application/ssdl+xml" => ["ssdl"],
    "application/ssml+xml" => ["ssml"],
    "application/tei+xml" => ["tei", "teicorpus"],
    "application/thraud+xml" => ["tfi"],
    "application/timestamped-data" => ["tsd"],
    "application/voicexml+xml" => ["vxml"],
    "application/wasm" => ["wasm"],
    "application/widget" => ["wgt"],
    "application/winhlp" => ["hlp"],
    "application/wsdl+xml" => ["wsdl"],
    "application/wspolicy+xml" => ["wspolicy"],
    "application/xaml+xml" => ["xaml"],
    "application/xcap-diff+xml" => ["xdf"],
    "application/xenc+xml" => ["xenc"],
    "application/xhtml+xml" => ["xhtml", "xht"],
    "application/xml" => ["xml", "xsl", "xsd", "rng"],
    "application/xml-dtd" => ["dtd"],
    "application/xop+xml" => ["xop"],
    "application/xproc+xml" => ["xpl"],
    "application/xslt+xml" => ["xslt"],
    "application/xspf+xml" => ["xspf"],
    "application/xv+xml" => ["mxml", "xhvml", "xvml", "xvm"],
    "application/yang" => ["yang"],
    "application/yin+xml" => ["yin"],
    "application/zip" => ["zip"],
    "audio/3gpp" => ["*3gpp"],
    "audio/adpcm" => ["adp"],
    "audio/basic" => ["au", "snd"],
    "audio/midi" => ["mid", "midi", "kar", "rmi"],
    "audio/mp3" => ["*mp3"],
    "audio/mp4" => ["m4a", "mp4a"],
    "audio/mpeg" => ["mpga", "mp2", "mp2a", "mp3", "m2a", "m3a"],
    "audio/ogg" => ["oga", "ogg", "spx"],
    "audio/s3m" => ["s3m"],
    "audio/silk" => ["sil"],
    "audio/wav" => ["wav"],
    "audio/wave" => ["*wav"],
    "audio/webm" => ["weba"],
    "audio/xm" => ["xm"],
    "font/collection" => ["ttc"],
    "font/otf" => ["otf"],
    "font/ttf" => ["ttf"],
    "font/woff" => ["*woff"],
    "font/woff2" => ["woff2"],
    "image/apng" => ["apng"],
    "image/bmp" => ["bmp"],
    "image/cgm" => ["cgm"],
    "image/g3fax" => ["g3"],
    "image/gif" => ["gif"],
    "image/ief" => ["ief"],
    "image/jp2" => ["jp2", "jpg2"],
    "image/jpeg" => ["jpeg", "jpg", "jpe"],
    "image/jpm" => ["jpm"],
    "image/jpx" => ["jpx", "jpf"],
    "image/ktx" => ["ktx"],
    "image/png" => ["png"],
    "image/sgi" => ["sgi"],
    "image/svg+xml" => ["svg", "svgz"],
    "image/tiff" => ["tiff", "tif"],
    "image/webp" => ["webp"],
    "message/disposition-notification" => ["disposition-notification"],
    "message/global" => ["u8msg"],
    "message/global-delivery-status" => ["u8dsn"],
    "message/global-disposition-notification" => ["u8mdn"],
    "message/global-headers" => ["u8hdr"],
    "message/rfc822" => ["eml", "mime"],
    "model/gltf+json" => ["gltf"],
    "model/gltf-binary" => ["glb"],
    "model/iges" => ["igs", "iges"],
    "model/mesh" => ["msh", "mesh", "silo"],
    "model/vrml" => ["wrl", "vrml"],
    "model/x3d+binary" => ["x3db", "x3dbz"],
    "model/x3d+vrml" => ["x3dv", "x3dvz"],
    "model/x3d+xml" => ["x3d", "x3dz"],
    "text/cache-manifest" => ["appcache", "manifest"],
    "text/calendar" => ["ics", "ifb"],
    "text/coffeescript" => ["coffee", "litcoffee"],
    "text/css" => ["css"],
    "text/csv" => ["csv"],
    "text/html" => ["html", "htm", "shtml"],
    "text/jade" => ["jade"],
    "text/jsx" => ["jsx"],
    "text/less" => ["less"],
    "text/markdown" => ["markdown", "md"],
    "text/mathml" => ["mml"],
    "text/n3" => ["n3"],
    "text/plain" => ["txt", "text", "conf", "def", "list", "log", "in", "ini"],
    "text/richtext" => ["rtx"],
    "text/rtf" => ["*rtf"],
    "text/sgml" => ["sgml", "sgm"],
    "text/shex" => ["shex"],
    "text/slim" => ["slim", "slm"],
    "text/stylus" => ["stylus", "styl"],
    "text/tab-separated-values" => ["tsv"],
    "text/troff" => ["t", "tr", "roff", "man", "me", "ms"],
    "text/turtle" => ["ttl"],
    "text/uri-list" => ["uri", "uris", "urls"],
    "text/vcard" => ["vcard"],
    "text/vtt" => ["vtt"],
    "text/xml" => ["*xml"],
    "text/yaml" => ["yaml", "yml"],
    "video/3gpp" => ["3gp", "3gpp"],
    "video/3gpp2" => ["3g2"],
    "video/h261" => ["h261"],
    "video/h263" => ["h263"],
    "video/h264" => ["h264"],
    "video/jpeg" => ["jpgv"],
    "video/jpm" => ["*jpm", "jpgm"],
    "video/mj2" => ["mj2", "mjp2"],
    "video/mp2t" => ["ts"],
    "video/mp4" => ["mp4", "mp4v", "mpg4"],
    "video/mpeg" => ["mpeg", "mpg", "mpe", "m1v", "m2v"],
    "video/ogg" => ["ogv"],
    "video/quicktime" => ["qt", "mov"],
    "video/webm" => ["webm"],
  }
end
