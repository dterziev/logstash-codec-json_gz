# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/codecs/json_gz"
require "logstash/codecs/base"
require "logstash/util/charset"
require "logstash/json"
require "logstash/event"
require "zlib"
require 'stringio'
require "logstash/errors"
require "insist"



def compress_with_gzip(io)
  compressed = StringIO.new
  gzip = Zlib::GzipWriter.new(compressed)
  gzip.write(io.read)
  gzip.finish
  compressed.rewind
  compressed
end

def uncompressed_log_array(n) 
  str = StringIO.new
  str << "["
  (1..n).each do |i| 
      str << "," if i > 1
      d = {"@timestamp" => DateTime.now.new_offset(0).strftime("%Y-%m-%dT%H:%M:%SZ"), "message" => "message #{i}"}
      str << LogStash::Json.dump(d) 
  end
  str << "]"
  str.rewind
  str
end

def uncompressed_log_lines(n) 
  str = StringIO.new
  (1..n).each do |i| 
      d = {"@timestamp" => DateTime.now.new_offset(0).strftime("%Y-%m-%dT%H:%M:%SZ"), "message" => "message #{i}"}
      str << LogStash::Json.dump(d) 
      str << "\n"
  end
  str.rewind
  str
end

def verify_decoded_events(data, event_count)
  events = []
  i = 0
  subject.decode(data) do |event|
    i += 1
    insist { event.is_a? LogStash::Event }
    insist { event.get("message") } == "message #{i}" 
    events << event
  end
        
  expect(events.size).to eq(event_count)
end

describe LogStash::Codecs::JsonGz do

  context "#decode" do

    event_count = 10000
    json_array_data = compress_with_gzip(uncompressed_log_array(event_count)).string
    json_lines_data = compress_with_gzip(uncompressed_log_array(event_count)).string
    json_object_data = compress_with_gzip(uncompressed_log_lines(1)).string

    context "when json_type = json" do
      
      subject{LogStash::Codecs::JsonGz.new("json_type" => "json")}

      it "should create events from gz json array" do
        verify_decoded_events(json_array_data, event_count)
      end
    
      it "should create events from gz json object" do
        verify_decoded_events(json_object_data, 1)
      end
    end

    context "when json_type = json_lines" do
      
      subject{LogStash::Codecs::JsonGz.new("json_type" => "json_lines")}

      it "should create events from gz json lines" do
        verify_decoded_events(json_lines_data, event_count)
      end
    
      it "should create events from gz json object" do
        verify_decoded_events(json_object_data, 1)
      end

    end

    context "when json_type = auto" do
      
      subject{LogStash::Codecs::JsonGz.new("json_type" => "auto")}
      
      it "should create events from gz json array" do
        verify_decoded_events(json_array_data, event_count)
      end

      it "should create events from gz json lines" do
        verify_decoded_events(json_lines_data, event_count)
      end
    
      it "should create events from gz json object" do
        verify_decoded_events(json_object_data, 1)
      end
      
    end
  end
end
