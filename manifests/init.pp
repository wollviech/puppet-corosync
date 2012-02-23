# Class: corosync
#
# Setup corosync on a node
#
# Parameters:
#	string $corosync_host_specific (default: undef):
#		Set to load nodeconfig::$corosync_host_specific::corosync
#	string $token_timeout (Default: 3000):
#		Time (in ms) for corosync token timeout
#	string $token_retransmit_count (Default: 10):
#		How often a lost token is retransmitted
#	string $join_wait (default: 60):
#		How long to wait for initial quorum when joining a new cluster
#	string $consens_time(default: 5000):
#		How long to wait for the consens algorithm once a cluster becomes quorate (in ms)
#	string $max_messages (default: 20):
#		Size of the transmit queue
#	enum $rrp_mode [passive|active|none] (default: passive):
#		Set the Redundant Ring Protocol mode for the Totem protocol:
#			active:: Faster faulty ring detection, higher bandwidth requirements
#			passive:: Slower faulty ring detection, lower bandwidth requirements
#			none:: No faulty ring detection
#	enum $transport_mode [udpu|bcast|mcast] (default: udpu):
#		Sets the transport mode corosync should use:
#			udpu:: UDP unicast
#			bcast:: UDP broadcast
#			mcast:: UDP Multicast
#	bool $pacemaker (default: true):
#		Whether to enable pacemaker integration
#	enum $secauth [on|off] (default: off):
#		Whether to enable symmetric encryption for message passing.
#		*Warning*: You *must* set an encryption key via $secauth_key if you enable encryption
#	string $secauth_key (default: undef):
#		Base64-encoded symmetric encryption key
#
# Dependencies:
#	- logrotate
#	- concat::setup
#
# Usage examples:
#	class {'corosync':
#       rrp_mode => 'active',
#       secauth => 'on',
#		secauth_key => '<hidden>'
#	}
#
class corosync (
	$corosync_host_specific = undef,
	$token_timeout = '3000',
	$token_retransmit_count = '10',
	$join_wait = '60',
	$consens_time = '5000',
	$max_messages = '20',
	$rrp_mode = 'passive',
	$transport_mode = 'udpu',
	$pacemaker = true,
	$secauth = 'off',
	$secauth_key = undef
){

	require corosync::params
	require logrotate::params
	require concat::setup
		

	if ($secauth != 'off' and $secauth_key == undef) {
		fail ("Corosync: Attempted to enable secure authentication without providing a shared secret (\$secauth_key = undef)")
	}

	package {$corosync::params::packagename:
		ensure => installed,
	}

	concat {$corosync::params::configfile:
		mode => $corosync::params::configfile_mode,
		owner => $corosync::params::configfile_owner,
		group => $corosync::params::configfile_group,
		require => Package[$corosync::params::packagename],
	}

	concat::fragment{ "corosync_header":
		target => $corosync::params::configfile,
		content => template("corosync/corosync_header.conf.erb"),
		order => 01,
	}

	concat::fragment { "corosync_footer":
		target => $corosync::params::configfile,
		content => template("corosync/corosync_footer.conf.erb"),
		order => 03,
	}


	# create logdir
	file {$corosync::params::logdir:
		ensure => directory,
	}

	# Deploy logrotate-config
	file{"$logrotate::params::logrotate_d/corosync":
		ensure => present,
		require => Package[$logrotate::params::packagename],
		content => template("corosync/logrotate.conf.erb"),
	}

	# Deploy secure authentication key (as base64)
	file{"${corosync::params::keyfile}.b64":
		ensure => present,
		content => $secauth_key,
		owner => 'root',
		group => 'root',
		mode => 400,
	}

	exec{"corosync-keyfile-decode":
		command => "base64 -d '${corosync::params::keyfile}.b64' > '${corosync::params::keyfile}'",
		refreshonly => true,
	}

	file{$corosync::params::keyfile:
		owner => 'root',
		group => 'root',
		mode => 400,
	}

	File["${corosync::params::keyfile}.b64"] ~> Exec['corosync-keyfile-decode']
	Exec['corosync-keyfile-decode'] -> File[$corosync::params::keyfile]

	# Ensure that the service is startet at boot time
	service{$corosync::params::servicename:
		enable => true,
		ensure => undef,
		require => [
				Package[$corosync::params::packagename], 
				Concat::Fragment["corosync_footer"],
			]
	}


	if $pacemaker {
		file {"${corosync::params::servicedir}/pacemaker":
			ensure => file,
			source => 'puppet:///modules/corosync/etc_corosync_service.d_pacemaker',
			checksum => md5,
			require => Package[$corosync::params::packagename],
		}

		File["${corosync::params::servicedir}/pacemaker"] -> Service[$corosync::params::servicename]
	}

	if ($corosync_host_specific) {
		include "nodeconfig::${corosync_host_specific}::corosync"
	}

	case $operatingsystem {
		Ubuntu,Debian: { include corosync::debian }
		default: {}
	}
}
