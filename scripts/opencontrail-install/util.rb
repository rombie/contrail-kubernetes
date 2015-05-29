#!/usr/bin/env ruby

require 'socket'
require 'ipaddr'
require 'pp'

def sh(cmd, ignore_exit_code = false, retry_count = 1, bg = false)
    puts cmd
    if bg then
        # Run command in background
        Process.detach(spawn(cmd))
        return
    end

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

def post_install()
    sh("nohup /vagrant/kube-network-manager 2>&1 > /var/log/contrail/kube-network-manager.log", false, 1, true)
    sh("python /opt/contrail/utils/provision_vgw_interface.py --oper create --interface vgw_public --subnets 10.1.0.0/16 --routes 0.0.0.0/0 --vrf default-domain:default-project:Public:Public")
    sh("ip route add 10.1.0.0/16 gw #{minion1_vgw}")
end

docker_ping if __FILE__ == $0
