#!/usr/bin/env ruby

@version = "2.20" # master

@common_packages = [
    "curl",
    "gdebi-core",
    "git",
    "gcc",
    "python-lxml",
    "python-setuptools",
    "python-software-properties",
    "software-properties-common",
    "sshpass",
    "strace",
    "tcpdump",
    "unzip",
    "vim",
    "wget",
]

# Download and extract contrail software which are missing in ppa
def download_contrail_software
    sh("wget -qO - https://github.com/rombie/opencontrail-packages/raw/R#{@version}/ubuntu1404/contrail.tar.xz | tar Jx", false, 5)
end

# Install from /cs-shared/builder/cache/centoslinux70/icehouse
def install_thirdparty_software_controller
    sh("apt-get -y install #{@common_packages.join(" ")}")
end

# Install contrail controller software
def install_contrail_software_controller
    sh("wget -q -O -  https://launchpad.net/~opencontrail/+archive/ubuntu/ppa/+files/nodejs_0.8.15-1contrail1_amd64.deb > nodejs_0.8.15-1contrail1_amd64.deb")
    sh("gdebi -n nodejs_0.8.15-1contrail1_amd64.deb")

    sh("curl -sL http://debian.datastax.com/debian/repo_key|sudo apt-key add -")
    sh(%{sh -c 'echo "deb http://debian.datastax.com/community/ stable main" >> /etc/apt/sources.list'})
    sh("add-apt-repository -y ppa:opencontrail/ppa")
    sh("add-apt-repository -y ppa:anantha-l/opencontrail-#{@version}")
    sh("apt-get -y --allow-unauthenticated update")
    sh("apt-get -y install --allow-unauthenticated openjdk-7-jre-headless=7u51-2.4.6-1ubuntu4") # openjdk-7-jre
    sh("apt-get -y --allow-unauthenticated install cassandra", true)

    # In certain instances such as aws, extra storage disk is at a different
    # mount point
    if @opt.cassandra_db_path != "/var/lib/cassandra"
        old_cassandra_dir = "/var/lib/cassandra/".gsub(/\//, '\/')
        new_cassandra_dir = "#{@opt.cassandra_db_path}/"
        sh("mkdir -p #{new_cassandra_dir}")
        sh("chown -R cassandra.cassandra #{new_cassandra_dir}")
        new_cassandra_dir.gsub!(/\//, '\/')
        sh(%{sed -i 's/#{old_cassandra_dir}/#{new_cassandra_dir}/' /etc/cassandra/cassandra.yaml})
    end
    sh(%{sed -i 's/start_rpc: false/start_rpc: true/' /etc/cassandra/cassandra.yaml})
    sh("service cassandra restart")

    sh("apt-get -y --allow-unauthenticated install contrail-analytics contrail-config contrail-control contrail-web-controller contrail-dns contrail-utils zookeeperd rabbitmq-server ifmap-server")
    sh("gdebi -n contrail-setup_*.deb")

    # Update time-zone
    sh("echo 'America/Los_Angeles' > /etc/timezone")
    sh("dpkg-reconfigure -f noninteractive tzdata")
end

def create_vhost_interface(ip, mask, gw)
    intf = "/etc/network/interfaces"
    `\grep vhost0 #{intf} 2>&1 > /dev/null`
    return if $?.to_i == 0

    ifcfg = <<EOF

auto vhost0
iface vhost0 inet static
      address #{ip}
      netmask #{mask}

EOF
    File.open(intf, "a") { |fp| fp.puts(ifcfg) }
end

# Install third-party software from /cs-shared/builder/cache/ubuntu1404/icehouse
def install_thirdparty_software_compute
    sh("apt-get -y install #{@common_packages.join(" ")}")
end

# Install contrail compute software
def install_contrail_software_compute
    sh("sync; echo 3 > /proc/sys/vm/drop_caches")
    sh("add-apt-repository -y ppa:opencontrail/ppa")
    sh("add-apt-repository -y ppa:anantha-l/opencontrail-#{@version}")
    sh("apt-get -y --allow-unauthenticated update")
    sh("apt-get -y --allow-unauthenticated install contrail-vrouter-agent contrail-vrouter-utils contrail-utils python-contrail-vrouter-api")

    # Install contrail-vrouter-init and contrail-setup packages also
    sh("gdebi -n contrail-vrouter-init_*.deb")
    sh("gdebi -n contrail-setup_*.deb")

    # Update time-zone
    sh("echo 'America/Los_Angeles' > /etc/timezone")
    sh("dpkg-reconfigure -f noninteractive tzdata")
end
