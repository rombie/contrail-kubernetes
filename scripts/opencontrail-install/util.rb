#!/usr/bin/env ruby

require 'socket'
require 'ipaddr'
require 'pp'

def sh(cmd, ignore_exit_code = false, retry_count = 1)
    puts cmd
    r = ""
    retry_count.times { |i|
        r = `#{cmd}`.chomp
        puts r
        break if $?.to_i == 0
        exit -1 if !ignore_exit_code and i == retry_count - 1
    }
    return r
end

def error(msg); puts msg; exit -1 end

# Return interface IP address, mask and gateway information
def get_intf_ip(intf)
    prefix = sh("ip addr show dev #{intf}|\grep -w inet | " +
                "\grep -v dynamic | awk '{print $2}'")
    error("Cannot retrieve #{intf}'s IP address") if prefix !~ /(.*)\/(\d+)$/
    ip = $1
    mask = IPAddr.new(prefix).inspect.split("/")[1].chomp.chomp(">")
    gw = sh(%{netstat -rn |\grep "^0.0.0.0" | awk '{print $2}'})

    return ip, mask, gw
end

def sh_container(container_id, cmd, ignore = false)
    pid = sh(%{docker inspect -f {{.State.Pid}} #{container_id}})
    sh(%{echo #{cmd} | nsenter -n -t #{pid} sh})
end

# Ping between two docker containers
def docker_ping()
    ips = [ ]
    pids = [ ]
    `docker ps |\grep pause |\grep front | awk '{print $1}'`.chomp.split.each { |docker|
        pid=`docker inspect -f {{.State.Pid}} #{docker}`.chomp
        cmd = %{echo ip address show dev eth0 | nsenter -n -t #{pid} sh | \grep -w inet | awk '{print $2}' | cut -d '/' -f 1}
        pids.push pid
        ips.push `#{cmd}`.chomp
    }

    cmd = %{echo ping -qc 1 #{ips[1]} | nsenter -n -t #{pids[0]} sh}
    puts cmd
    puts `#{cmd}`
    cmd = %{echo ping -qc 1 #{ips[0]} | nsenter -n -t #{pids[1]} sh}
    puts cmd
    puts `#{cmd}`
    # docker ps |\grep -v CO | awk '{print $1}' | xargs -n 1 docker kill
end

def setup_simple_gateway()
    `echo 127.0.0.1 localhost >> /etc/hosts`
    `ip route add 10.0.2.0/29 dev p2p1`

    # Create Public network, floatingip pool and associate 10.0.2.0/24 subnet,
    # and allocate/reserve first 7 addresses.

    `python /opt/contrail/utils/provision_vgw_interface.py --oper create --interface vgw1 --subnets 10.0.2.0/24 --routes 0.0.0.0/0 --vrf default-domain:default-project:Public:Public`

end

docker_ping if __FILE__ == $0
