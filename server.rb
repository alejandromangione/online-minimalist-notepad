require "socket"
# require_relative "request"
# require_relative "response"
require 'uri'
require 'securerandom'

port = ENV.fetch("PORT", 3000).to_i
default_path = ENV.fetch("DEFAULT_PATH", nil)
server = TCPServer.new port

class Response
  def initialize(code:, body: "")
    @code = code
    @body = body
  end

  def send(client)
    client.print "HTTP/1.1 #{@code}\r\n"
    client.print "Content-Type: text/html\r\n"
    client.print "Content-Length: #{@body.length}\r\n"
    client.print "\r\n"
    client.print @body if !@body.empty?

    puts "-> #{@code}"
  end
end

class Request
  attr_reader :method, :path, :headers, :body, :query

  def initialize(request)
    lines = request.lines
    index = lines.index("\r\n")

    @method, @path, _ = lines.first.split
    @path, @query = @path.split("?")
    @headers = parse_headers(lines[1...index])
    @body = lines[(index + 1)..-1].join

    puts "<- #{@method} #{@path} #{@body}"
  end

  def parse_headers(lines)
    headers = {}

    lines.each do |line|
      name, value = line.split(": ")
      headers[name] = value.chomp
    end

    headers
  end

  def content_length
    headers["Content-Length"].to_i
  end
end

puts "Listening on port #{port}..."

def handle_get(request)
  if ["/script.js", "/styles.css"].include? request.path
    full_path = File.join(__dir__, request.path)

    Response.new(code: 200, body: File.binread(full_path))
  else
    full_path = File.join(__dir__, 'tmp', request.path)

    if File.exists?(full_path)
      content = File.read(full_path)
    end

    body = <<~STR
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Online Minimalist Notepad</title>
          <link rel="icon" href="favicon.ico" sizes="any">
          <link rel="icon" href="favicon.svg" type="image/svg+xml">
          <link rel="stylesheet" href="styles.css">
        </head>
        <body>
            <div class="container">
              <textarea id="content" spellcheck="false">#{content}</textarea>
            </div>
            <pre id="printable"></pre>
            <script src="script.js"></script>
        </body>
      </html>
    STR

    Response.new(code: 200, body: body)
  end
end

def handle_post(request)
  full_path = File.join(__dir__, 'tmp', request.path)
  content = request.body.split('=').last

  decoded_body = URI.decode_www_form_component(content)
  File.write(full_path, decoded_body)

  Response.new(code: 200)
end

loop do
  Thread.start(server.accept) do |client|
    request = Request.new client.readpartial(20480)

    if request.path == "/"
      path = default_path || SecureRandom.hex

      client.print "HTTP/1.1 303 See Other\r\n"
      client.print "Location: #{path}\r\n"
      client.print "\r\n"

    elsif request.method == "GET"
      response = handle_get(request)
      response.send(client)

    else request.method == "POST"
      response = handle_post(request)
      response.send(client)
    end

    client.close
  end
end
