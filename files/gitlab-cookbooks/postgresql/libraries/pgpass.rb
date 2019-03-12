class Pgpass
  attr_accessor :hostname, :port, :database, :username, :password, :host_user, :userinfo

  # @param [String] username for the database connection
  # @param [String] password for the database connection
  # @param [String] host_user the system user that should own and hold the .pgpass file
  # @param [String] hostname for the database connection
  # @param [String] port for the database connection
  # @param [String] database name for the connection
  def initialize(username:, password:, host_user:, hostname: '*', port: '*', database: '*')
    @hostname = hostname
    @port = port
    @database = database
    @username = username
    @password = password
    @host_user = host_user
    @userinfo = Etc.getpwnam(host_user)
  end

  # Renders the .pgpass file content
  #
  # @return [String] .pgpass file content
  def render
    ERB.new(pgpass_template).result(binding)
  end

  # Filename with full path of the .pgpass file for the +host_user+
  #
  # @return [String] filename with full path
  def filename
    "#{userinfo.dir}/.pgpass"
  end

  private

  def pgpass_template
    "<%= hostname %>:<%= port %>:<%= database %>:<%= username %>:<%= password %>"
  end
end
