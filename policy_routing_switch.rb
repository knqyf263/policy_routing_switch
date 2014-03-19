class PolicyRoutingSwitch < Controller
  require 'mysql2'

  # init
  @mac_addr   = ""
  @current_port = 0

  def switch_ready( datapath_id )
    puts "switch #{ datapath_id.to_hex } is connected."
  end

  def packet_in datapath_id, message
    p ExactMatch.from(message).to_s

    in_port = message.in_port
    p in_port
    p message.macsa
    dst_port = select_mac_db(message.macsa.to_s.upcase)

    if in_port == 13
      if dst_port != nil
        p "dst_port:#{dst_port}"
        flow_mod datapath_id, message, dst_port.to_i
        packet_out datapath_id, message, dst_port.to_i 
      else
        flow_mod datapath_id, message, 12 
        packet_out datapath_id, message, 12
      end
    elsif in_port == 12
      flow_mod datapath_id, message, 13 
      packet_out datapath_id, message, 13
    elsif in_port == 11
      flow_mod datapath_id, message, 13 
      packet_out datapath_id, message, 13
    elsif in_port == 15
      flow_mod datapath_id, message, 13 
      packet_out datapath_id, message, 13
   end
  end


  def flow_mod datapath_id, message, port_no 
    send_flow_mod_add(
      datapath_id,
#      :priority => 0x1,
      :idle_timeout => 10,
      :match => ExactMatch.from( message ),
      :actions => ActionOutput.new( :port => port_no )
    )
  end

  def port_flow_mod datapath_id, in_port, out_port
    send_flow_mod_add(
      datapath_id,
#      :priority => 0x1,
      :match => Match.new( :in_port => in_port),
      :actions => ActionOutput.new( :port => out_port)
    )
  end

  def packet_out datapath_id, message, port_no
    send_packet_out(
      datapath_id,
      :packet_in => message,
      :actions => ActionOutput.new( :port => port_no )
    )
  end



  def select_mac_db(macaddr)
    puts "hoge"
    # connect to DB
    client = Mysql2::Client.new(:host => "127.0.0.1",
                  :username => "user",
                  :password => "password",
                  :database => "macdb")
  
    # query
    #search_query = "select macaddr, port from macaddrs where name = #{@user_name}"
    search_query = "SELECT port FROM macaddrs LEFT JOIN port_table ON macaddrs.id = port_table.macaddr_id where macaddr = '#{macaddr}'"
    result = client.query(search_query)
  
    result.each do |row|
      @current_port = row["port"]
      puts @current_port
    end
  
#    warn "[Mac Addr  ] #{@mac_addr} "
    warn "[Port in DB] #{@current_port} "
    client.close
    return @current_port
  end
end


