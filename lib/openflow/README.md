For the controller, we are interested to create a description object, on which lib users can register for callback for specific events. Not sure whether the list of event will be constant, or we can expand it. 

--

networking setup: virtualbox on osx, ubuntu 10.04 LTS server (64bit)

setup en3 on osx - manually configured - 172.16.0.1/255.255.255.0 
setup bootpd on osx
  - sudo /bin/launchctl load -w /System/Library/LaunchDaemons/bootps.plist
  - [sudo /bin/launchctl unload -w /System/Library/LaunchDaemons/bootps.plist]

  /etc/bootpd.plist

: mort@greyjay:~$; cat /etc/bootpd.plist 
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Subnets</key>
	<array>
		<dict>
			<key>allocate</key>
			<true/>
			<key>lease_max</key>
			<integer>86400</integer>
			<key>lease_min</key>
			<integer>86400</integer>
			<key>name</key>
			<string>172.16.0</string>
			<key>net_address</key>
			<string>172.16.0.0</string>
			<key>net_mask</key>
			<string>255.255.255.0</string>
			<key>net_range</key>
			<array>
				<string>172.16.0.2</string>
				<string>172.16.0.254</string>
			</array>
		</dict>
	</array>
	<key>bootp_enabled</key>
	<false/>
	<key>detect_other_dhcp_server</key>
	<false/>
	<key>dhcp_enabled</key>
	<array>
		<string>en3</string>
	</array>
	<key>reply_threshold_seconds</key>
	<integer>0</integer>
</dict>
</plist>

  /etc/bootptab

: mort@greyjay:~$; cat /etc/bootptab 
%%
# machine entries have the following format:
#
# hostname        hwtype  hwaddr            ipaddr     bootfile
greyjay-ubuntu-1  1       08:00:27:38:72:c6 172.16.0.11
greyjay-ubuntu-2  1       08:00:27:11:dd:a0 172.16.0.12


set each vm to have two adapters
  - eth0/bridged connected to en1 (or en0)
  - eth1/bridged connected to en3

set ssh keys and adjust sshd_config setting to disallow passwords

install packages
  openssh-server
  git-core
  build-essential
  autoconf
  libtool
  pkg-config
  libboost1.40-all-dev
  libssl-dev
  swig

pull and build openvswitch and nox
  git clone git://openvswitch.org/openvswitch
  cd openvswitch/
  ./boot.sh 
  ./configure --with-linux=/lib/modules/`uname -r`/build
  make -j6
  make && sudo make install
  cd ..

  git clone git://noxrepo.org/nox
  cd nox
  ./boot.sh
  ../configure
  make -j5

install kernel module
  sudo insmod ~/openvswitch/datapath/linux/openvswitch_mod.ko

setup ovs
  sudo ovsdb-server ./openvswitch/ovsdb.conf --remote=punix:/var/run/ovsdb-server
  ovsdb-tool create ovsdb.conf vswitchd/vswitch.ovsschema
  sudo ovs-vswitchd unix:/var/run/ovsdb-server
  sudo ovs-vsctl --db=unix:/var/run/ovsdb-server init
  sudo ovs-vsctl --db=unix:/var/run/ovsdb-server add-br dp0
  sudo ovs-vsctl --db=unix:/var/run/ovsdb-server set-fail-mode dp0 secure
  sudo ovs-vsctl --db=unix:/var/run/ovsdb-server set-controller dp0 tcp:172.16.0.1:6633
  sudo ovs-vsctl --db=unix:/var/run/ovsdb-server add-port dp0 eth0

set ip addrs on ifaces
  sudo ifconfig eth0 0.0.0.0
  sudo ifconfig dp0 <whatever-eth0-was>

