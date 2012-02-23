# Class corosync::debian
#
# Contains Debian/Ubuntu-specific configuration directives
# for corosync.
# 
# Do *not* call directly, will automatically be called
# by corosync::init
#
class corosync::debian 
{

	require corosync::params

	$str = "# File managed by puppet
	# start corosync at boot [yes|no]
	START=yes"


	file {'/etc/default/corosync':
		content => $str,
		require => Package[$corosync::params::packagename],
		before => Service[$corosync::params::servicename],
	}
		

}
