# Define corosync::interface
#
# Defines a corosync *unicast UDP* interface 
# (in other words: Do only use if you set +udpu+ as transport mode)
#
# It will also automatically create an iptables-rule
#
# Parameters:
#	string[] $member (default: empty):
#		Array of member IP addresses
#	int $port (default: 5405):
#		Port to use. 
#		*Warning* : Corosync will use $port *and* $port -1 
#	int $ringnumber (default: 0):
#		Ring-sequencenumber. The first ring must be number 0.
#	string $network_address:
#		Network base address for the subnet.
#
# Usage examples:
#     corosync::interface{'heartbeat':
#       member => [
#               $nodeconfig::siskofrisko::ips::sisko['heartbeat'],
#               $nodeconfig::siskofrisko::ips::frisko['heartbeat'],
#           ],
#       port => 5405,
#       ringnumber => 0,
#       network_address => '192.168.9.32',
#   }
#
define corosync::interface (
	$member = [],
	$port = 5405,
	$ringnumber = 0,
	$network_address
){

	require concat::setup
	require corosync::params

	concat::fragment {"corosync_$name":
		target => $corosync::params::configfile,
		content => template('corosync/corosync_udpu_interface.conf.erb'),
		order => 02,
	}

	$port_1 = $port - 1

	$firewallrule = "${corosync::params::firewalldir}/corosync_${name}"
	file {$firewallrule:
		ensure => present,
		checksum => md5,
		content => template('corosync/corosync_iptables.erb'),
		require => Package['komstuff'],
	}


	exec {"activate-iptables-corosync_${name}":
		command => "/sbin/iptables-restore --noflush < '${firewallrule}'",
		refreshonly => true,
		onlyif => "test -f '${firewallrule}'",
	}

	File[$firewallrule] ~> Exec["activate-iptables-corosync_${name}"]

}
