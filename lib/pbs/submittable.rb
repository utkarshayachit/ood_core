require "socket"
require "tempfile"

module PBS
  module Submittable
    HOSTNAME = Socket.gethostname

    def headers
      {
        ATTR[:N] => "Jobname",
        ATTR[:o] => "#{Dir.pwd}/",
        ATTR[:e] => "#{Dir.pwd}/",
        ATTR[:j] => "oe",
      }.merge @headers
    end

    def resources
      {
        nodes: "1:ppn=#{conn.batch_ppn}",
        walltime: "00:10:00",
      }.merge @resources
    end

    def envvars
      {
        PBS_O_WORKDIR: "#{Dir.pwd}",
      }.merge @envvars
    end

    # Can submit a script as a file or string
    # The PBS headers defined in the file will NOT be parsed
    # all PBS headers must be supplied programmatically
    def submit(args = {})
      file = args[:file]
      string = args[:string] || File.open(file).read
      queue = args[:queue]

      @headers = args[:headers] || {}
      @resources = args[:resources] || {}
      @envvars = args[:envvars] || {}

      # Create batch script in tmp file, submit, remove tmp file
      script = Tempfile.new('qsub.')
      begin
        script.write string
        script.close
        _pbs_submit(script.path, queue)
      ensure
        script.unlink # deletes the temp file
      end

      self
    end

    # Connect to server, submit job with headers,
    # disconnect, and finally check for errors
    def _pbs_submit(script, queue)
      # Generate attribute hash for this job
      attribs = headers
      attribs[ATTR[:l]] = resources
      attribs[ATTR[:v]] = envvars.map{|k,v| "#{k}=#{v}"}.join(",")

      # Filter some of the attributes
      attribs[ATTR[:o]].prepend("#{HOSTNAME}:")
      attribs[ATTR[:e]].prepend("#{HOSTNAME}:")

      # Submit job
      conn.connect unless conn.connected?
      attropl = Torque::Attropl.from_hash(attribs)
      self.id = Torque.pbs_submit(conn.conn_id, attropl, script, queue, nil)
      conn.disconnect
      Torque.check_for_error
    end
  end
end
