# encoding: utf-8
require "logstash/codecs/base"
require "logstash/util/charset"
require "logstash/json"
require "logstash/event"
require "zlib"
require 'stringio'

# This codec will read gzip encoded json content. 
#
# Example usage:
#
# input {
#  tcp { 
#    port=>5004
#    codec => json_gz { json_type => "auto" }
#  }
# }
#
class LogStash::Codecs::JsonGz < LogStash::Codecs::Base
  config_name "json_gz"

  # The character encoding used in this codec. Examples include "UTF-8" and
  # "CP1252"
  #
  # JSON requires valid UTF-8 strings, but in some cases, software that
  # emits JSON does so in another encoding (nxlog, for example). In
  # weird cases like this, you can set the charset setting to the
  # actual encoding of the text and logstash will convert it for you.
  #
  # For nxlog users, you'll want to set this to "CP1252"
  config :charset, :validate => ::Encoding.name_list, :default => "UTF-8"

  # The expected format of each event. The following are supported
  # "json" - for json documents or json arrays (default).
  # "json_lines" - json lines delimited by '\n'.
  # "auto" - attempts to auto-detect if the json represents an array or lines.
  config :json_type, :validate => ["json","json_lines", "auto"], :default => "json"

  public

  def register
    @converter = LogStash::Util::Charset.new(@charset)
    @converter.logger = @logger
  end

  def decode(data, &block)
    data = decompress(StringIO.new(data), &block) 
    data = @converter.convert(data)

    if @json_type == "json" || (@json_type == "auto" && data[0] == '[')
      from_json_parse(data, &block)
    else 
      data.each_line { |l| from_json_parse(l, &block) } 
    end
    
  rescue => e
    @logger.error("err: #{e}")
    yield LogStash::Event.new("message" => data, "tags" => ["_jsongzparsefailure"])
  end

  def encode(data)
    raise RuntimeError.new("This codec is only used to decode gzip encoded json.")
  end

  private

  def from_json_parse(json, &block)
    LogStash::Event.from_json(json).each { |event| yield event }
  rescue LogStash::Json::ParserError => e
    @logger.error("JSON parse error, original data now in message field", :error => e, :data => json)
    yield LogStash::Event.new("message" => json, "tags" => ["_jsonparsefailure"])
  end 

  def decompress(data)
    gz = Zlib::GzipReader.new(data)
    gz.read
  rescue Zlib::Error, Zlib::GzipFile::Error => e
    @logger.error("Error decompressing gzip data: #{e}")
    raise
  end

end # class LogStash::Codecs::JsonGz
