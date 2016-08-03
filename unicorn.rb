# Set the working application directory
# working_directory "/path/to/your/app"
working_directory "/var/www/disc"

# Unicorn PID file location
# pid "/path/to/pids/unicorn.pid"
pid "/var/www/disc/pids/unicorn.pid"

# Path to logs
# stderr_path "/path/to/logs/unicorn.log"
# stdout_path "/path/to/logs/unicorn.log"
stderr_path "/var/www/disc/logs/unicorn-err.log"
stdout_path "/var/www/disc/logs/unicorn.log"

# Unicorn socket
# listen "/tmp/unicorn.[app name].sock"
listen "127.0.0.1:3003"

# Number of processes
# worker_processes 4
worker_processes 2

# Time-out
timeout 30
