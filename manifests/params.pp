# Class corosync::params
# 
# This class will automatically synthesize certain variables and paths
# based on facter values
#
class corosync::params {

	$packagename = ['corosync', 'libcorosync4']
	$servicename = 'corosync'
	
	$confdir = '/etc/corosync'

	$configfile = "${confdir}/corosync.conf"

	$keyfile = "${confdir}/authkey"

	$servicedir = "${confdir}/service.d"

	$firewalldir = "/etc/iptables.d"

	$configfile_owner = 'root'
	$configfile_group = 'root'
	$configfile_mode = '644'

	$logdir = '/var/log/corosync'
	$logfile = "${logdir}/corosync.log"
	$logfile_ringsize = '31'
	$logfile_compress = 'nocompress'
}
