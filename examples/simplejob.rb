require 'pbs'
require 'yaml'

# Use default torque lib
PBS::Torque.init

# Set up connection to local server
c = PBS::Conn.new

# Check info for local server
q = PBS::Query.new(conn: c, type: :server)
puts "# Batch server information ---"
puts q.find.to_yaml
puts ""

# Check if I have any jobs currently running
q = PBS::Query.new(conn: c, type: :job)
filters = [PBS::ATTR[:state], PBS::ATTR[:owner]]
puts "# All jobs you currently have in the batch ---"
puts q.where(user: ENV['USER']).find(filters: filters).to_yaml
puts ""

# Setup new job
j = PBS::Job.new(conn: c)

headers = { PBS::ATTR[:N] => "SimpleJob" }
resources = { nodes: "1:ppn=1", walltime: "00:10:00" }
envvars = { WORLD: "world" }
script = "echo \"Hello ${WORLD}!\""


# Submit new job
puts "# Submitting new job ---"
puts j.submit(string: script, headers: headers, resources: resources, envvars: envvars).id
puts ""

# Show details of new job
puts "# Details of submitted job ---"
puts j.status.to_yaml
puts ""

# Hold job
puts "# Holding job now ---"
j.hold
puts j.status(filter: PBS::ATTR[:state]).to_yaml
puts ""

# Show only jobs on hold
puts "# All running jobs on hold ---"
puts q.where(user: ENV['USER']).where(PBS::ATTR[:state] => 'H').find(filters: filters).to_yaml
puts ""
puts "# All running jobs not on hold ---"
puts q.where(user: ENV['USER']).wherenot(PBS::ATTR[:state] => 'H').find(filters: filters).to_yaml
puts ""
puts "# All running jobs not queued ---"
puts q.where(user: ENV['USER']).wherenot(PBS::ATTR[:state] => 'Q').find(filters: filters).to_yaml
puts ""

# Release job
puts "# Releasing job now ---"
j.release
puts j.status(filter: PBS::ATTR[:state]).to_yaml
puts ""

# Delete submitted job
puts "# Deleting job now ---"
j.delete
puts "Complete."
puts ""
