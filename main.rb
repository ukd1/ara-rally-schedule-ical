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
  url = "https://r.jina.ai/https://www.americanrallyassociation.org/2024-ara-schedule"
  result = fetch_url(url)
  File.write('ara-schedule.md', result)

  client =  OpenAI::Client.new(access_token: ENV["OPENAI_KEY"])

  response = client.chat(
      parameters: {
          model: "gpt-4o",
          messages: [{
            role: "user",
            content: "Please just output raw ICS (no code-block) - make a list of ARA rallies in 2024 in from this data:\n\n#{result}"
          }]
      })

  r = response.dig("choices", 0, "message", "content")

  strict_parser = Icalendar::Parser.new(r, true)
  strict_parser.parse

  File.write("ara-schedule.ics", r)
rescue => e
  puts "An error occurred: #{e.message}"
end
