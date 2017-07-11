require 'sequel'
require 'odbc'
require 'mixins/cached_logger'

module ETL::Redshift

  # when the odbc driver is setup in chef this is the driver's name
  REDSHIFT_ODBC_DRIVER_NAME="MyRedshiftDriver"

  # Class that contains shared logic for accessing Redshift.
  class Client
    include ETL::CachedLogger
    attr_accessor :driver, :server, :db, :port, :username, :password, :connected
    def initialize(conn_params={})
      @driver = conn_params[:driver] || REDSHIFT_ODBC_DRIVER_NAME
      @server = conn_params[:host] || "localhost"
      @db_name = conn_params[:database] || "dev"
      @port =  conn_params[:port] || 5439
      @password = conn_params[:password]
      @user = conn_params[:user]
      ObjectSpace.define_finalizer(self, proc { @db.disconnect })
      @connected = false
    end

    def connect
      if !@connected then
        connect_str = "Driver={#{@driver}}; Servername=#{@server}; Database=#{@db_name}; UID=#{@user}; PWD=#{@password}; Port=#{@port}"
        puts "connect str:#{connect_str}"
        @db = Sequel.odbc(:drvconnect=> connect_str)
        @connected = true
      end
    end

    def execute(sql)
      connect
      log.debug(sql)
      @db.execute(sql)
    end

    def fetch(sql)
      connect
      log.debug(sql)
      @db.fetch(sql)
    end

    def drop_table(table_name)
      sql = "drop table if exists #{table_name};"
      execute(sql)
    end

    def columns(table_name)
      sql = <<SQL
      SELECT "column", type FROM pg_table_def WHERE tablename = '#{table_name}'
SQL
      fetch(sql).all
    end
  end

end
