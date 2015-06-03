#!/usr/bin/env ruby

# Use this script to install and provision contrail nodes.
# sudo ruby $PWD/contrail-kubernetes/scripts/opencontrail-install/contrail_install.rb

raise 'Must run with superuser privilages' unless Process.uid == 0

@ws="#{File.dirname($0)}"
require "#{@ws}/util"
STDOUT.sync = true

sh("\grep aurora /etc/hostname", true)
@controller_host = $?.to_i == 0 ? "aurora" : "kubernetes-master"
@intf = "eth0"
@user = "ubuntu"

# Find platform OS
sh(%{\grep -i "ubuntu 14" /etc/issue 2>&1 > /dev/null}, true)
@platform = $?.to_i == 0 ? "ubuntu1404" : "fedora20"

@control_node_introspect_port = @controller_host == "aurora" ? 9083 : "8083"

require "#{@ws}/#{@platform}/install"

# Update ssh configuration
def ssh_setup
    conf=<<EOF
UserKnownHostsFile=/dev/null
StrictHostKeyChecking=no
LogLevel=QUIET
EOF
    sh("mkdir -p /root/.ssh")
    File.open("/root/.ssh/config", "a") { |fp| fp.puts(conf) }
    sh("chmod 600 /root/.ssh/config")

    # Add ssh config to ~@user also.
    sh("mkdir -p /home/#{@user}/.ssh")
    File.open("/home/#{@user}/.ssh/config", "a") { |fp| fp.puts(conf) }
    sh("chmod 600 /home/#{@user}/.ssh/config")
    sh("chown #{@user}.#{@user} /home/#{@user}/.ssh/config")
    sh("chown #{@user}.#{@user} /home/#{@user}/.ssh/.")
end

# Do initial setup
def initial_setup
    @resolvers = sh("\grep -w nameserver /etc/resolv.conf").split("\n")
    ssh_setup
    sh("service hostname restart", true) if @platform !~ /fedora/
#   @contrail_controller = IPSocket.getaddress(@controller_host)
    @contrail_controller =
        sh(%{grep #{@controller_host} /etc/hosts | awk '{print $1}'})
    error "Cannot resolve contrail-controller host" \
        if @contrail_controller.empty?

    # Make sure that localhost resolves to 127.0.0.1
    sh(%{\grep -q "127\.0\.0\.1.*localhost" /etc/hosts}, true)
    sh("echo 127.0.0.1 localhost >> /etc/hosts") if $?.to_i != 0

    Dir.chdir("#{@ws}")
end

def update_controller_etc_hosts
    # Update /etc/hosts with the IP address
    @controller_ip, mask, gw, prefix_len = get_intf_ip(@intf)

    rip = sh("\grep #{@controller_host} /etc/hosts | awk '{print $1}'", true)
    return if rip != "127.0.0.1" and !rip.empty?

    # If @controller_host resolves to 127.0.0.1, take it out of /etc/hosts
    sh("sed -i '/127.0.0.1 #{@controller_host}/d' /etc/hosts") \
        if rip == "127.0.0.1"
    sh("echo #{@controller_ip} #{@controller_host} >> /etc/hosts")
end

def verify_controller
    sh("netstat -anp | \grep LISTEN | \grep -w 5672", false, 10, 3) # RabbitMQ
    sh("netstat -anp | \grep LISTEN | \grep -w 2181", false, 10, 3) # ZooKeeper
    sh("netstat -anp | \grep LISTEN | \grep -w 9160", false, 10, 3) # Cassandra
    sh("netstat -anp |\grep LISTEN | \grep -w #{@control_node_introspect_port}",
       false, 10, 3) # Control-Node
    sh("netstat -anp | \grep LISTEN | \grep -w 5998", false, 10, 3) # discovery
    sh("netstat -anp | \grep LISTEN | \grep -w 6379", false, 10, 3) # redis
    sh("netstat -anp | \grep LISTEN | \grep -w 8443", false, 10, 3) # IFMAP
    sh("netstat -anp | \grep LISTEN | \grep -w 8082", false, 10, 3) # API-Server
    sh("netstat -anp | \grep LISTEN | \grep -w 8086", false, 10, 3) # Collector
    sh("netstat -anp | \grep LISTEN | \grep -w 8081", false, 10, 3) # OpServer
    sh("netstat -anp | \grep LISTEN | \grep -w 8143", false, 10, 3) # WebUI
    sh("netstat -anp | \grep LISTEN | \grep -w 8070", false, 10, 3) # WebUI

    puts "All contrail controller components up"
end

# Provision contrail-controller
def provision_contrail_controller
    update_controller_etc_hosts

    sh(%{sed -i 's/Xss180k/Xss280k/' /etc/cassandra/conf/cassandra-env.sh})
    sh(%{echo "api-server:api-server" >> /etc/ifmap-server/basicauthusers.properties})
    sh(%{echo "schema-transformer:schema-transformer" >> /etc/ifmap-server/basicauthusers.properties})
    sh(%{echo "svc-monitor:svc-monitor" >> /etc/ifmap-server/basicauthusers.properties})
    sh(%{echo "control-user:control-user-passwd" >> /etc/ifmap-server/basicauthusers.properties})
    sh(%{sed -i 's/911%(process_num)01d/5998/' /etc/contrail/supervisord_config_files/contrail-discovery.ini})
    sh(%{sed -i 's/91%(process_num)02d/8082/' /etc/contrail/supervisord_config_files/contrail-api.ini})
    sh(%{sed -i 's/# port=5998/port=5998/' /etc/contrail/contrail-control.conf})
    sh(%{sed -i 's/# server=127.0.0.1/server=127.0.0.1/' /etc/contrail/contrail-control.conf})
    sh(%{sed -i 's/# port=5998/port=5998/' /etc/contrail/contrail-collector.conf})
    sh(%{sed -i 's/# server=0.0.0.0/server=127.0.0.1/' /etc/contrail/contrail-collector.conf})
    sh(%{sed -i 's/# user=control-user/user=control-user/g' /etc/contrail/contrail-control.conf})
    sh(%{sed -i 's/# password=control-user-passwd/password=control-user-passwd/' /etc/contrail/contrail-control.conf})
    sh(%{sed -i 's/Xss180k/Xss280k/' /etc/cassandra/conf/cassandra-env.sh})

    # Fix webui config
    sh("ln -sf /usr/bin/nodejs /usr/bin/node")
    sh(%{sed -i 's/8080/8070/' /etc/contrail/config.global.js})

    if @platform =~ /fedora/
        sh("service cassandra restart")
        sh("service zookeeper restart")
        sh("service redis restart")
    else
        sh("service redis-server restart")
    end
    sh("service rabbitmq-server restart")
    sh("service supervisor-database restart")
    sh("service supervisor-control restart")
    sh("service supervisor-config restart")
    sh("service supervisor-analytics restart")
    sh("service supervisor-webui restart")

    60.times {|i| print "\rWait for #{i}/60 seconds to settle down.. "; sleep 1}
    verify_controller

    sh(%{python /opt/contrail/utils/provision_control.py --api_server_ip } +
       %{#{@controller_ip} --api_server_port 8082 --router_asn 64512 } +
       %{--host_name #{@controller_host} --host_ip #{@controller_ip} } +
       %{--oper add })
end

def verify_compute
    5.times {|i| print "\rWait for #{i}/5 seconds to settle down.. "; sleep 1}
    sh("lsmod |\grep vrouter")
    sh("netstat -anp | \grep -w LISTEN | \grep -w 8085")
    sh("ping -c 3 #{@controller_host}")
    sh("ping -c 3 github.com")
end

# Provision contrail-vrouter agent and vrouter kernel module
def provision_contrail_compute
    ip, mask, gw, prefix_len = get_intf_ip(@intf)
    create_vhost_interface(ip, mask, gw)

    sh("sed 's/__DEVICE__/#{@intf}/' /etc/contrail/agent_param.tmpl > /etc/contrail/agent_param")
    sh("sed -i 's/# type=kvm/type=kvm/' /etc/contrail/contrail-vrouter-agent.conf")
    sh("touch /etc/contrail/default_pmac")
    sh("sed -i 's/# name=vhost0/name=vhost0/' /etc/contrail/contrail-vrouter-agent.conf")
    sh("sed -i 's/# physical_interface=vnet0/physical_interface=#{@intf}/' /etc/contrail/contrail-vrouter-agent.conf")
    sh("sed -i 's/# server=10.204.217.52/server=#{@contrail_controller}/' /etc/contrail/contrail-vrouter-agent.conf")
    sh("sed -i 's/# ip=[0-9]\\+\.[0-9]\\+\.[0-9]\\+\.[0-9]\\+\\/[0-9]\\+/ip=#{ip}\\/#{prefix_len}/' /etc/contrail/contrail-vrouter-agent.conf")
    sh("sed -i 's/# gateway=[0-9]\\+\.[0-9]\\+\.[0-9]\\+\.[0-9]\\+/gateway=#{gw}/' /etc/contrail/contrail-vrouter-agent.conf")

    sh("sshpass -p #{@user} ssh -t #{@user}@#{@controller_host} sudo python /opt/contrail/utils/provision_vrouter.py --host_name #{sh('hostname')} --host_ip #{ip} --api_server_ip #{@contrail_controller} --oper add")
    sh("service supervisor-vrouter restart")
    sh("service contrail-vrouter-agent restart")

    # Remove ip address from the interface as that is taken over by vhost0
    sh("ifdown #{@intf}; ifup #{@intf}")
    sh("ip addr flush dev #{@intf}")

    # Restore default route
    sh("ip route add 0.0.0.0/0 via #{gw}", true)

    # Restore DNS resolver
    # @resolvers.each { |r| sh(%{sh -c "echo #{r} >> /etc/resolv.conf"}) }
    verify_compute
end

def provision_contrail_controller_kubernetes
    return # if @controller_host !~ /kubernetes/

    # Start kube web server in background
    # http://localhost:8001/static/app/#/dashboard/
    sh("nohup kubectl proxy --www=/#{@user}/www 2>&1 > /var/log/kubectl-web-proxy.log", false, 1, 1, true)

    # Start kube-network-manager plugin daemon in background
    sh("nohup /#{@user}/kube-network-manager 2>&1 > /var/log/contrail/kube-network-manager.log", false, 1, 1, true)
end

def provision_contrail_compute_kubernetes
    return if @controller_host !~ /kubernetes/
    Dir.chdir("#{@ws}/../opencontrail-kubelet")
    sh("python setup.py install")
    plugin = "opencontrail"
    sh("mkdir -p /usr/libexec/kubernetes/kubelet-plugins/net/exec/#{plugin}")
    path = @platform =~ /fedora/ ? "/usr/bin/opencontrail-kubelet-plugin" :
                                   "/usr/local/bin/opencontrail-kubelet-plugin"
    sh("ln -sf #{path} " +
       "/usr/libexec/kubernetes/kubelet-plugins/net/exec/#{plugin}/#{plugin}")

    # Generate default plugin configuration file
    plugin_conf = <<EOF
[DEFAULTS]
api_server = #{@contrail_controller}
net_mode = bridge
EOF
    File.open("/usr/libexec/kubernetes/kubelet-plugins/net/exec/#{plugin}/config", "w") { |fp|
        fp.puts plugin_conf
    }

    if @platform =~ /fedora/
        sh(%{sed -i 's/DAEMON_ARGS=" /DAEMON_ARGS=" --network_plugin=#{plugin} /' /etc/sysconfig/kubelet})
        sh("systemctl restart kubelet", true)
    else
        sh(%{sed -i 's/DAEMON_ARGS /DAEMON_ARGS --network_plugin=#{plugin} /' /etc/default/kubelet})
        sh("service docker stop", true)
        sh("rm -rf /mnt/docker")
        sh("service docker restart", true)
        sh("service kubelet restart", true)
        sh("service kube-proxy stop", true)
    end
end

def aws_setup
    # Update /etc/hosts
    # Allow password based login in ssh
end

def main
    initial_setup
    download_contrail_software
    if ARGV[0] == "controller" or ARGV[0] == "all" then
        install_thirdparty_software_controller
        install_contrail_software_controller
        provision_contrail_controller
        provision_contrail_controller_kubernetes
    end
    if ARGV[0] == "compute" or ARGV[0] == "all" then
        install_thirdparty_software_compute
        install_contrail_software_compute
        provision_contrail_compute
        provision_contrail_compute_kubernetes
    end
end

main
