require "rails"

rails_env = Rails.env.to_s

if ! ENV['RAILS_ENV']
   # required in prod since it is blank
   ENV['RAILS_ENV'] = Rails.env = rails_env = 'production'
end

$stdout.puts "{puma.rb}: rails_env: #{rails_env}, ENV[RAILS_ENV]: #{ENV['RAILS_ENV']}"

environment rails_env

if Rails.env.production? || Rails.env.staging?
   app_dir = File.expand_path("../..", __FILE__)
   if /releases/ =~ app_dir
      shared_dir = File.expand_path("#{app_dir}/../../shared")
   else
      shared_dir = File.expand_path("#{app_dir}/../shared")
   end
   $stdout.puts "{puma.rb}: shared_dir #{shared_dir}"
   $stdout.puts "{puma.rb}: env: #{ENV.inspect}"
   threads_count = Integer(ENV['MAX_THREADS'] || 10)

   workers Integer(ENV['WEB_CONCURRENCY'] || 2)
   bind "unix://#{shared_dir}/sockets/puma-geyser.sock"
   stdout_redirect "#{shared_dir}/log/stdout.log", "#{shared_dir}/log/stderr.log", true
   pidfile "#{shared_dir}/tmp/pids/puma.pid"
   state_path "#{shared_dir}/tmp/pids/puma.state"
   activate_control_app
   daemonize false # required for foreman and systemd
elsif Rails.env.development?
   shared_dir = '.'
   threads_count = Integer(ENV['MAX_THREADS'] || 1)
   port = ENV['PORT'] || 33333
   host = ENV['HOST'] || '0.0.0.0'

   worker_timeout 3600
   workers Integer(ENV['WEB_CONCURRENCY'] || 1)
   bind "tcp://#{host}:#{port}"
   rackup DefaultRackup
end

threads threads_count, threads_count

preload_app!

$stdout.puts "{puma.rb}: booted"
