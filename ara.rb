require 'openai'
require 'net/http'
require 'uri'
require 'icalendar'

def fetch_url(url)
  uri = URI.parse(url)
  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{ENV["JINA_KEY"]}"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.request(request)
  end

  if response.code.to_i == 200
    response.body
  else
    raise "HTTP GET Request failed with response code #{response.code}"
  end
end

begin
  print "Pulling ARA page as markdown..."
  result = fetch_url("https://r.jina.ai/https://www.americanrallyassociation.org/2024-ara-schedule")
  File.write('ara-schedule.md', result)
  puts "✅"

  print "Using OpenAI to convert to ICS..."
  response = OpenAI::Client.new(access_token: ENV["OPENAI_KEY"]).chat(
      parameters: {
          model: "gpt-4o",
          messages: [{
            role: "user",
            content: "Please just output raw ICS with no code-block, please validate the output. Use a URL field for the URL. UID should be the URL of the individual rally. States should be full names. VEVENT fields should be in the following order; include only - UID, URL, SUMMARY, DTSTART, DTEND, LOCATION, ATTACH. Use ATTACH to put the logo from each event properly.
            Make a list of ARA rallies in from this data:\n\n#{result}"
          }]
      })

  r = response.dig("choices", 0, "message", "content")
  puts "✅"

  print "Validating ICS..."
  strict_parser = Icalendar::Parser.new(r, true)
  strict_parser.parse
  puts "✅"



  File.write("ara-schedule.ics", r)
rescue => e
  puts "❌ An error occurred: #{e.message}"
end
