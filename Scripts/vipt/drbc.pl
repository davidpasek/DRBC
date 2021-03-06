#!/usr/bin/perl -w
#
# Copyright 2006 DELL, Inc.  All rights reserved.
#

use strict;
use warnings;

use VMware::VIRuntime;
use Data::Dumper;
use AppUtil::VMUtil;
use Net::SMTP;

require '../config/vipt.conf.pl';
require '../common/datetime.pl';
require '../common/debug.pl';

my %opts = (
   action  => {
      type     => "=s",
      variable => "",
      help     => "Perform selected operation:\n" . 
                  "\t\tlist_standby_servers\n" . 
                  "\t\tcheck_primary_servers_if_exist_snapshot\n" . 
		  "\t\tshutdown_standby_servers\n" . 
		  "\t\tshutdown_standby_servers_without_vc\n" . 
		  "\t\tshutdown_primary_servers_without_vc\n" . 
		  "\t\tshutdown_replicator_without_vc\n" . 
		  "\t\tshutdown_vc_without_vc\n" . 
		  "\t\tshutdown_primary_dc_without_vc\n" . 
		  "\t\tshutdown_standby_dc_without_vc\n" . 
		  "\t\tstart_standby_servers\n" .
		  "\t\tstart_standby_servers_without_vc\n" .
		  "\t\tstart_primary_servers_without_vc\n" .
		  "\t\tstart_replicator_without_vc\n" .
		  "\t\tstart_vc_without_vc\n" .
		  "\t\tstart_primary_dc_without_vc\n" .
		  "\t\tstart_standby_dc_without_vc\n" . 
		  "\t\trelocate_standby_servers_into_standby_pool\n" .
		  "\t\trelocate_standby_servers_into_standby_network\n" .
		  "\t\trelocate_standby_servers_into_appropriate_networks\n" .
		  "\t\trelocate_standby_servers_into_appropriate_networks_without_vc\n" .
		  "\t\trelocate_standby_dc_into_standby_networks_without_vc\n" .
		  "\t\trelocate_primary_servers_into_appropriate_networks_without_vc\n" .
		  "\t\trelocate_primary_servers_into_standby_networks_without_vc\n",
      required => 1},
   wait_for_powered_off  => {
      type     => "",
      help     => "use with action [shutdown_standby_server]",
      required => 0},
   unregister  => {
      type     => "",
      help     => "use with action [shutdown_standby_server]",
      required => 0},
   deletefromdisk  => {
      type     => "",
      help     => "delete from disk & unregister - use with action [shutdown_standby_server]",
      required => 0},
   remove_rdm  => {
      type     => "",
      help     => "remove rdm disks - use with action [shutdown_standby_server]",
      required => 0},
   add_rdm  => {
      type     => "",
      help     => "add rdm disks - use with action [shutdown_standby_server]",
      required => 0},
   sleep_interval  => {
      type     => "=s",
      help     => "wait (in seconds) between particular shutdowns - use with actions [shutdown_*]",
      required => 0},
);

&debug_start();
my %drbc_config = &getConfig();
my $ERROR_LEVEL = 0;

# START - read/validate options
Opts::add_options(%opts);
Opts::parse();

# set default values when not defined
my $url = Opts::get_option ('url');
if ($url ne 'https://localhost/sdk/webService') {
	&debug ("URL of VMware SOAP server (from outside parameter): $url");
} else {
	$url = 'https://' . $drbc_config{'VC'}{'HOSTNAME'} . '/sdk/webService';
	&debug ("URL of VMware SOAP server (redefined from config): $url");
	Opts::set_option('url', $url );
};

if (!Opts::get_option ('username')) {
	Opts::set_option('username', $drbc_config{'VC'}{'USERNAME'} );
};

if (!Opts::get_option ('password')) {
	Opts::set_option('password', $drbc_config{'VC'}{'PASSWORD'} );
};

Opts::validate();
# END - read/validate options

my $option_unregister = 0;
if (Opts::get_option ('unregister')) {$option_unregister=1;};

my $option_deletefromdisk = 0;
if (Opts::get_option ('deletefromdisk')) {$option_deletefromdisk=1;};

my $option_remove_rdm = 0;
if (Opts::get_option ('remove_rdm')) {$option_remove_rdm=1;};

my $option_wait_for_powered_off = 0;
if (Opts::get_option ('wait_for_powered_off')) {$option_wait_for_powered_off=1;};

my $option_add_rdm = 0;
if (Opts::get_option ('add_rdm')) {$option_add_rdm=1;};

my $option_sleep_interval = 0;
if (Opts::get_option ('sleep_interval')) {$option_sleep_interval=Opts::get_option ('sleep_interval');};

my $a = Opts::get_option ('action');
SWITCH: {
  if ($a eq "shutdown_standby_servers") { &shutdown_standby_servers(); last SWITCH; }
  if ($a eq "shutdown_standby_servers_without_vc") { 
	  &shutdown_servers_without_vc ( in_datacenter => "backup", servers => "all"); last SWITCH; }
  if ($a eq "shutdown_primary_servers_without_vc") { 
	  &shutdown_servers_without_vc ( in_datacenter => "primary", servers => "all" ); last SWITCH; }
  if ($a eq "check_primary_servers_if_exist_snapshot") { 
	  &check_primary_servers_if_exist_snapshot ( in_datacenter => "primary" ); last SWITCH; }
  if ($a eq "shutdown_replicator_without_vc") { 
	  &shutdown_servers_without_vc ( in_datacenter => "backup" , servers => $drbc_config{'DRBC'}{'REPLICATOR'} ); last SWITCH; }
  if ($a eq "shutdown_vc_without_vc") { 
	  &shutdown_servers_without_vc ( in_datacenter => "primary" , servers => $drbc_config{'DRBC'}{'VC'} ); last SWITCH; }
  if ($a eq "shutdown_primary_dc_without_vc") { 
	  &shutdown_servers_without_vc ( in_datacenter => "primary" , servers => $drbc_config{'DRBC'}{'DC'} ); last SWITCH; }
  if ($a eq "shutdown_standby_dc_without_vc") { 
	  &shutdown_servers_without_vc ( in_datacenter => "backup" , servers => $drbc_config{'DRBC'}{'DC'} ); last SWITCH; }
  if ($a eq "start_standby_servers") { &start_standby_servers(); last SWITCH; }
  if ($a eq "start_standby_servers_without_vc") { 
	  &start_servers_without_vc ( in_datacenter => "backup", servers => "all" ); last SWITCH; }
  if ($a eq "start_primary_servers_without_vc") { 
	  &start_servers_without_vc ( in_datacenter => "primary", servers => "all" ); last SWITCH; }
  if ($a eq "start_replicator_without_vc") { 
	  &start_servers_without_vc ( in_datacenter => "backup", servers => $drbc_config{'DRBC'}{'REPLICATOR'} ); last SWITCH; }
  if ($a eq "start_vc_without_vc") { 
	  &start_servers_without_vc ( in_datacenter => "primary", servers => $drbc_config{'DRBC'}{'VC'} ); last SWITCH; }
  if ($a eq "start_primary_dc_without_vc") { 
	  &start_servers_without_vc ( in_datacenter => "primary", servers => $drbc_config{'DRBC'}{'DC'} ); last SWITCH; }
  if ($a eq "start_standby_dc_without_vc") { 
	  &start_servers_without_vc ( in_datacenter => "backup" , servers => $drbc_config{'DRBC'}{'DC'} ); last SWITCH; }
  if ($a eq "list_standby_servers") { &list_standby_servers(); last SWITCH; }
  if ($a eq "relocate_standby_servers_into_standby_pool") { &relocate_standby_servers_into_standby_pool(); last SWITCH; }
  if ($a eq "relocate_standby_servers_into_standby_network") { 
	  &relocate_servers_into_network ( in_datacenter => "backup", to_network => "standby" ); last SWITCH; }
  if ($a eq "relocate_standby_servers_into_appropriate_networks") { 
	  &relocate_servers_into_network ( in_datacenter => "backup", to_network => "appropriate" ); last SWITCH; }
  if ($a eq "relocate_standby_servers_into_appropriate_networks_without_vc") { 
	  &relocate_servers_into_network_without_vc ( in_datacenter => "backup", to_network => "appropriate", servers => "all" ); last SWITCH; }
  if ($a eq "relocate_standby_servers_into_standby_network_without_vc") { 
	  &relocate_servers_into_network_without_vc ( in_datacenter => "backup", to_network => "standby", servers => "all" ); last SWITCH; }
  if ($a eq "relocate_standby_dc_into_standby_network_without_vc") { 
	  &relocate_servers_into_network_without_vc ( in_datacenter => "backup", to_network => "standby", servers => $drbc_config{'DRBC'}{'DC'} ); 
	  last SWITCH; }
  if ($a eq "relocate_primary_servers_into_appropriate_networks_without_vc") { 
	  &relocate_servers_into_network_without_vc ( in_datacenter => "primary", to_network => "appropriate", servers => "all" ); last SWITCH; }
  if ($a eq "relocate_primary_servers_into_standby_networks_without_vc") { 
	  &relocate_servers_into_network_without_vc ( in_datacenter => "primary", to_network => "standby", servers => "all" ); last SWITCH; }
  &debug("!!!! Undefined action !!!!");
}

&debug("ERROR_LEVEL=$ERROR_LEVEL");
&debug_end();
exit $ERROR_LEVEL;

#############################################################
# Connect to URL - vmware SOAP server
# return 0/1 - fail/success
############################################################# 
sub vi_connect_to_url {
	# Connect to URL
	eval {Util::connect()};
	if ($@) {
	  my $server_fault=$@;
	  my $log_msg = " Connection to VC or ESX was unsuccessfull (" . $server_fault. ")";
	  &debug($log_msg);
	  return 0;
	}
	return 1;
}


#############################################################
# Disconnect from URL - vmware SOAP server
# return 0/1 - fail/success
############################################################# 
sub vi_disconnect_from_url {
	# disconnect from the server
	Util::disconnect();                                  
	if ($@) {
	  my $server_fault=$@;
	  my $log_msg = " Disconnection from VC or ESX was unsuccessfull (" . $server_fault. ")";
	  &debug($log_msg);
	  &fail("Die script with ERROR_LEVEL=1");
	}
	return 1;
}

#############################################################
# Shutdown Servers Without VC
#   &shutdown_servers_without_vc ( in_datacenter => "backup" ) // all configured servers
#   &shutdown_servers_without_vc ( in_datacenter => "primary" ) // all configured servers
#   &shutdown_servers_without_vc ( in_datacenter => "backup" , servers => "REPLIKATOR") // only server REPLIKATOR
#
#   Return: 0/1 ... fail/success
############################################################# 
sub shutdown_servers_without_vc {
  my %params = @_;

  my %drbc_config = &getConfig();

  # Check parameter - in_datacenter
  my $datacenter_view;
  my $datacenter_name;
  if ($params{in_datacenter} eq "backup") {
  	  $datacenter_name = &get_backup_datacenter();
	  &debug("Shutdown servers in BACKUP datacenter: $datacenter_name");
  } elsif ($params{in_datacenter} eq "primary") {
  	  $datacenter_name = &get_primary_datacenter();
	  &debug("Shutdown servers in PRIMARY datacenter: $datacenter_name");
  } else {
	  &debug("Parameter 'in_datacenter' must be PRIMARY or BACKUP");
	  return 0;
  }

  # Traverse all ESX's in datacenter (primary or backup)
  # $CONFIG{'ESX'}{'HOST'}{'ESX4-BS'}{'DATACENTER'} = "Bardosova";
  # $CONFIG{'DRBC'}{'ESX_SERVERS'} = "ESX1-PS ESX2-PS ESX3-PS ESX4-PS ESX1-BS ESX2-BS ESX3-BS ESX4-BS";
  # $CONFIG{'ESX'}{'CREDENTIALS'}{'USERNAME'} = "root";
  # $CONFIG{'ESX'}{'CREDENTIALS'}{'PASSWORD'} = "password";

  # $vm_esx{VMNAME} = ESX-HOST; # so for example $vm_esx{LL-DB}='ESX2-BS';
  my %vm_esx = &CheckWhatVmsAreOnWhichEsx('datacenter' => $datacenter_name);

  # START - SHUTDOWN SERVERS
  my @servers;
  if (!$params{servers}) {
	 &debug("Parameter 'servers' must be ALL or list of servers delimited by space");
	 return 0;
  } elsif (lc($params{servers}) eq "all") {
	 @servers = split(/ /, $drbc_config{'DRBC'}{'SERVER_SHUTDOWN_ORDER'});
  } else {
	 @servers = split(/ /, $params{servers});
  }

  foreach (@servers) {
     my $server=$_; # server name
   
     my $esx = $vm_esx{$server};
     if (!$esx) {
	     &debug("VM $server has not been located.");
	     next;
     }
     my $esx_datacenter_name = $drbc_config{'ESX'}{'HOST'}{$esx}{'DATACENTER'};
     my $esx_hostname = $drbc_config{'ESX'}{'HOST'}{$esx}{'HOSTNAME'};
     my $esx_ip = $drbc_config{'ESX'}{'HOST'}{$esx}{'IP'};
     my $esx_username = $drbc_config{'ESX'}{'CREDENTIALS'}{'USERNAME'};
     my $esx_password = $drbc_config{'ESX'}{'CREDENTIALS'}{'PASSWORD'};

     # Work only with ESX hosts in selected datacenter
     if ($esx_datacenter_name ne $datacenter_name) {
	     &debug("ESX is not in right datacenter ... very strange.");
	     next;
     }

     &debug("ESX name: $esx",10);
     &debug("ESX datacenter name: $esx_datacenter_name",10);
     &debug("ESX hostname: $esx_hostname",10);
     &debug("ESX IP: $esx_ip",10);

     my $esx_soap_url = 'https://' . $esx_hostname . '/sdk/webService';
     &debug ("URL of VMware ESX SOAP server (redefined from config): $esx_soap_url",1);
     Opts::set_option('url', $esx_soap_url );
     Opts::set_option('username', $esx_username );
     Opts::set_option('password', $esx_password );

     # Connect to URL (ESX)
     if (!&vi_connect_to_url()) {
	     &debug("Connection to ESX hostname has been unsuccesfull ... try connect to ESX IP ...");
             $esx_soap_url = 'https://' . $esx_ip . '/sdk/webService';
             &debug ("URL of VMware ESX SOAP server (redefined from config): $esx_soap_url",1);
     	     Opts::set_option('url', $esx_soap_url );
	     if (!&vi_connect_to_url()) {
	        &debug("Connection to ESX IP has been unsuccesfull ... try next ESX host");
		next;
	     }
     }

     my %filter = (); 
     $filter{'name'} = $server;
     my $vm_view = Vim::find_entity_view(view_type => 'VirtualMachine',
                                             filter => \%filter);
     unless ($vm_view) {
         &debug("Virtual Machine $server not found.");
         # Disconnect from URL (ESX)
         &vi_disconnect_from_url();
         next;
     }

     my $vm_is_replicated = &in_array($vm_view->name,&get_replicated_servers());
     my $vm_powerstate=$vm_view->runtime->powerState->val;
 
     my $vm_tools_status="unknown";
     if ($vm_view->guest) {
        if ($vm_view->guest->toolsStatus) {
          $vm_tools_status=$vm_view->guest->toolsStatus->val;
        }
     }
     my $vm_action_msg = "";
     my $server_fault;
     my $log_msg;

     &debug( "****************************");
     &debug( "SERVER NAME : " . $server );
     &debug( "DATACENTER : " . $datacenter_name );
     &debug( "VM NAME    : " . $vm_view->name );
     &debug( "VM IS REPLICATED FROM PS TO BS? (0..no, 1..yes): " . $vm_is_replicated );
     &debug( "VM POWER STATE: " . $vm_powerstate );
     &debug( "VM TOOLS STATUS: " . $vm_tools_status );
     &debug("****************************");

	# TRY SHUTDOWN OTHERWISE POWEROFF     
        if ($vm_powerstate eq 'poweredOn') {
	       if (uc($vm_tools_status) eq uc("toolsOK")) {
		 $vm_action_msg.="Shuting down this virtual machine ...";
	       
		 # START EVAL SHUTDOWNGUEST
       		 &debug("Shutting down VM ...");
		 eval {$vm_view->ShutdownGuest();};
		 if ($@) {
		   $server_fault=$@;
		   $log_msg = " shuting down was unsuccessfull (" . $server_fault. ") ... let's Power Off ...";
		   $vm_action_msg .= $log_msg;
		   &debug($log_msg);
		   $vm_view->PowerOffVM();  
		 } else {
		       # Wait for poweredOff state of VM otherwise power it off manualy
		       if (not &vm_wait_for_poweredOff($vm_view,300)) {
			   &debug("Power Off this virtual machine manualy...");
			   eval {$vm_view->PowerOffVM();}
		       }
	         }
		 # END EVAL SHUTDOWNGUEST
	       } else {
		 $vm_action_msg .= "Power Off this virtual machine ...";
		 eval {$vm_view->PowerOffVM();}
	       }
       }
       # END TRY SHUTDOWN OTHERWISE POWEROFF
      
       # SLEEP A WHILE
       if ($option_sleep_interval>0) {
       	  &debug("Sleep for $option_sleep_interval seconds ...");
	  sleep($option_sleep_interval);
       }

       # TRY REMOVE RDM
       if ($option_remove_rdm) {
       	 &debug("Remove RDM ...");
	 # Wait for poweredOff state of VM otherwise power it off manualy
	 if (not &vm_wait_for_poweredOff($vm_view,300)) {
	   &debug("Power Off this virtual machine manualy...");
	   eval {$vm_view->PowerOffVM();}
	 }

	 # Now try remove RDM disks
	 if (&remove_rdm_disks($vm_view)) {;
	   $vm_action_msg .= " If RDM disks existed they have been removed...";
         }
       }
       # END TRY REMOVE RDM

       # TRY ADD RDM
       if ($option_add_rdm) {
       	 &debug("Add RDM ...");
	 if (&add_rdm_disks($vm_view)) {;
	   $vm_action_msg .= "... adding RDM disks passed ...";
         }
       }
       # END TRY ADD RDM
       
       # TRY DELETE FROM DISK
       if ($option_deletefromdisk) {
       	 &debug("Delete from disk ...");
	 # Wait for poweredOff state of VM otherwise power it off manualy
	 if (not &vm_wait_for_poweredOff($vm_view,300)) {
	   &debug("Power Off this virtual machine manualy...");
	   eval {$vm_view->PowerOffVM();}
	 }

	 $vm_action_msg .= " deleting VM from disk ...";
         eval {
	 	&debug("Destroying virtual machine (unregister & delete from disk) ...");
		$vm_view->Destroy();
	 };
         if ($@) {
           $server_fault=$@;
           $log_msg = " delete has been unsuccessfull (" . $server_fault. ")";
	   $vm_action_msg .= $log_msg;
	   &debug($log_msg);
         }
       }
       # END TRY DELETE FROM DISK

       # TRY UNREGISTER
       if ($option_unregister) {
       	 &debug("Unregister ...");
	 # Wait for poweredOff state of VM otherwise power it off manualy
	 if (not &vm_wait_for_poweredOff($vm_view,300)) {
	   &debug("Power Off this virtual machine manualy...");
	   eval {$vm_view->PowerOffVM();}
	 }

	 $vm_action_msg .= " unregistering VM ...";
         eval {$vm_view->UnregisterVM();};
         if ($@) {
           $server_fault=$@;
           $log_msg = " unregistering has been unsuccessfull (" . $server_fault. ")";
	   $vm_action_msg .= $log_msg;
	   &debug($log_msg);
         }
       }
       # END TRY UNREGISTER

     &debug("VM ACTION: $vm_action_msg");
     &debug("****************************");

  }
  # END - SHUTDOWN SERVERS

  return 1;
}
# Function End


#############################################################
# Start Servers Without VC
#   &start_servers_without_vc ( in_datacenter => "backup" ) // all configured servers
#   &start_servers_without_vc ( in_datacenter => "primary" ) // all configured servers
#   &start_servers_without_vc ( in_datacenter => "backup" , servers => "REPLIKATOR") // only server REPLIKATOR
#
#   Return: 0/1 ... fail/success
############################################################# 
sub start_servers_without_vc {
  my %params = @_;

  my %drbc_config = &getConfig();

  # Check parameter - in_datacenter
  my $datacenter_view;
  my $datacenter_name;
  if ($params{in_datacenter} eq "backup") {
  	  $datacenter_name = &get_backup_datacenter();
	  &debug("Start servers in BACKUP datacenter: $datacenter_name");
  } elsif ($params{in_datacenter} eq "primary") {
  	  $datacenter_name = &get_primary_datacenter();
	  &debug("Start servers in PRIMARY datacenter: $datacenter_name");
  } else {
	  &debug("Parameter 'in_datacenter' must be PRIMARY or BACKUP");
	  return 0;
  }

  # Traverse all ESX's in datacenter (primary or backup)
  # $CONFIG{'ESX'}{'HOST'}{'ESX4-BS'}{'DATACENTER'} = "Bardosova";
  # $CONFIG{'DRBC'}{'ESX_SERVERS'} = "ESX1-PS ESX2-PS ESX3-PS ESX4-PS ESX1-BS ESX2-BS ESX3-BS ESX4-BS";
  # $CONFIG{'ESX'}{'CREDENTIALS'}{'USERNAME'} = "root";
  # $CONFIG{'ESX'}{'CREDENTIALS'}{'PASSWORD'} = "password";

  my @esx_servers = split (/ /, $drbc_config{'DRBC'}{'ESX_SERVERS'} );

  # $vm_esx{VMNAME} = ESX-HOST; # so for example $vm_esx{LL-DB}='ESX2-BS';
  my %vm_esx = &CheckWhatVmsAreOnWhichEsx('datacenter' => $datacenter_name);

  # START SERVERS
  my @servers;
  if (!$params{servers}) {
	 &debug("Parameter 'servers' must be ALL or list of servers delimited by space");
	 return 0;
  } elsif (lc($params{servers}) eq "all") {
	 @servers = split(/ /, $drbc_config{'DRBC'}{'SERVER_STARTUP_ORDER'});
  } else {
	 @servers = split(/ /, $params{servers});
  }

  foreach (@servers) {
     my $server=$_; # server name
   
     my $esx = $vm_esx{$server};
     if (!$esx) {
	     &debug("VM $server has not been located.");
	     next;
     }
     my $esx_datacenter_name = $drbc_config{'ESX'}{'HOST'}{$esx}{'DATACENTER'};
     my $esx_hostname = $drbc_config{'ESX'}{'HOST'}{$esx}{'HOSTNAME'};
     my $esx_ip = $drbc_config{'ESX'}{'HOST'}{$esx}{'IP'};
     my $esx_username = $drbc_config{'ESX'}{'CREDENTIALS'}{'USERNAME'};
     my $esx_password = $drbc_config{'ESX'}{'CREDENTIALS'}{'PASSWORD'};

     # Work only with ESX hosts in selected datacenter
     if ($esx_datacenter_name ne $datacenter_name) {
	     &debug("ESX is not in right datacenter ... very strange.");
	     next;
     }

     &debug("ESX name: $esx",10);
     &debug("ESX datacenter name: $esx_datacenter_name",10);
     &debug("ESX hostname: $esx_hostname",10);
     &debug("ESX ip: $esx_ip",10);

     my $esx_soap_url = 'https://' . $esx_hostname . '/sdk/webService';
     &debug ("URL of VMware ESX SOAP server (redefined from config): $esx_soap_url",1);
     Opts::set_option('url', $esx_soap_url );
     Opts::set_option('username', $esx_username );
     Opts::set_option('password', $esx_password );

     # Connect to URL (ESX)
     if (!&vi_connect_to_url()) {
	     &debug("Connection to ESX hostname has been unsuccesfull ... try connect to ESX IP ...");
             $esx_soap_url = 'https://' . $esx_ip . '/sdk/webService';
             &debug ("URL of VMware ESX SOAP server (redefined from config): $esx_soap_url",1);
     	     Opts::set_option('url', $esx_soap_url );
	     if (!&vi_connect_to_url()) {
	        &debug("Connection to ESX IP has been unsuccesfull ... try next ESX host");
		next;
	     }
     }

     my %filter = (); 
     $filter{'name'} = $server;
     my $vm_view = Vim::find_entity_view(view_type => 'VirtualMachine',
                                             filter => \%filter);
     unless ($vm_view) {
         &debug("Virtual Machine $server not found.");
         # Disconnect from URL (ESX)
         &vi_disconnect_from_url();
         next;
     }

     my $vm_is_replicated = &in_array($vm_view->name,&get_replicated_servers());
     my $vm_powerstate=$vm_view->runtime->powerState->val;
 
     my $vm_tools_status="unknown";
     if ($vm_view->guest) {
        if ($vm_view->guest->toolsStatus) {
          $vm_tools_status=$vm_view->guest->toolsStatus->val;
        }
     }
     my $vm_action_msg = "";
     my $vmname = $vm_view->name;

     &debug( "****************************");
     &debug( "SERVER NAME : " . $server );
     &debug( "DATACENTER : " . $datacenter_name );
     &debug( "VM NAME    : " . $vmname );
     &debug( "VM IS REPLICATED FROM PS TO BS? (0..no, 1..yes): " . $vm_is_replicated );
     &debug( "VM POWER STATE: " . $vm_powerstate );
     &debug( "VM TOOLS STATUS: " . $vm_tools_status );
     &debug("****************************");

     #TESTS BEFORE POWERON
     &pre_post_tests(vmname => $vmname, type => 'BEFORE_POWER_ON');

     # START - POWERON STANDBY SERVER
     if ($vm_powerstate ne 'poweredOn') {

	&debug("Starting virtual machine ...");
	$vm_action_msg = "PowerOn VM";
	
	my $vm_poweron_task;
	$vm_poweron_task = $vm_view->PowerOnVM_Task();
	 
	# START - CHECK IF POWERON IS SUCCESSFULL
	my $curr_state="running";
	my $rotation = 0;
	do
	{
		sleep(15);
		my $my_vm = Vim::get_view(mo_ref => $vm_poweron_task);
		$curr_state=$my_vm->info->state->val;
		$rotation=$rotation+1;
		&debug(" ... current state: " . $curr_state . " ... (rotation $rotation) waiting 15 sec.");

		&AnswerVMQuestionWithDefaultAnswer(vmname => $vm_view->name);
	}
	until( ($curr_state eq 'success')  || ($curr_state eq 'error') ); 

     	if ($curr_state ne 'success') {
    		&debug("PowerOn Task failed with state: $curr_state");
     	} else {
		&debug("PowerOn has been successfull.");
     	}
	# END - CHECK IF POWERON IS SUCCESSFULL

     }
     # END - POWERON STANDBY SERVER

     &debug("VM ACTION: $vm_action_msg");
     &debug("****************************");

     #TESTS AFTER POWERON
     &pre_post_tests(vmname => $vmname, type => 'AFTER_POWER_ON');
  }

  return 1;
}
# Function End

#############################################################
# Relocate Servers into STANDBY/APPROPRIATE Network/s
#   &relocate_servers_into_network_without_vc ( in_datacenter => "backup", to_network => "standby", servers => "ALL" )
#   &relocate_servers_into_network_without_vc ( in_datacenter => "backup", to_network => "appropriate", servers => "DC" )
#   &relocate_servers_into_network ( in_datacenter => "primary", to_network => "standby" )
#   &relocate_servers_into_network ( in_datacenter => "primary", to_network => "appropriate" )
#
#   Return: 0/1 ... fail/success
############################################################# 
sub relocate_servers_into_network_without_vc {
  my %params = @_;

  my %drbc_config = &getConfig();

  # Check parameter - to_network
  if ($params{to_network} eq "standby") {
	  &debug("Relocate servers into STANDBY network");
  } elsif ($params{to_network} eq "appropriate") {
	  &debug("Relocate servers into APPROPRIATE networks");
  } else {
	  &debug("Parameter 'to_network' must be STANDBY or APPROPRIATE");
	  # Disconnect from URL (VC SOAP Server)
	  return 0;
  }

  # Check parameter - in_datacenter
  my $datacenter_view;
  my $datacenter_name;
  if ($params{in_datacenter} eq "backup") {
  	  $datacenter_name = &get_backup_datacenter();
	  &debug("Relocate servers in BACKUP datacenter: $datacenter_name");
  } elsif ($params{in_datacenter} eq "primary") {
  	  $datacenter_name = &get_primary_datacenter();
	  &debug("Relocate servers in PRIMARY datacenter: $datacenter_name");
  } else {
	  &debug("Parameter 'in_datacenter' must be PRIMARY or BACKUP");
	  return 0;
  }

  my @servers;
  if (!$params{servers}) {
	 &debug("Parameter 'servers' must be ALL or list of servers delimited by space");
	 return 0;
  } elsif (lc($params{servers}) eq "all") {
	 @servers = split(/ /, $drbc_config{'DRBC'}{'SERVER_SHUTDOWN_ORDER'});
  } else {
	 @servers = split(/ /, $params{servers});
  }

  # Traverse all ESX's in datacenter (primary or backup)
  # $vm_esx{VMNAME} = ESX-HOST; # so for example $vm_esx{LL-DB}='ESX2-BS';
  my %vm_esx = &CheckWhatVmsAreOnWhichEsx('datacenter' => $datacenter_name);

  # START -  RELOCATE SERVERS INTO NETWORKS
  foreach (@servers) {
     my $server=$_; # server name
   
     my $esx = $vm_esx{$server};
     if (!$esx) {
	     &debug("VM $server has not been located.");
	     next;
     }
     my $esx_datacenter_name = $drbc_config{'ESX'}{'HOST'}{$esx}{'DATACENTER'};
     my $esx_hostname = $drbc_config{'ESX'}{'HOST'}{$esx}{'HOSTNAME'};
     my $esx_ip = $drbc_config{'ESX'}{'HOST'}{$esx}{'IP'};
     my $esx_username = $drbc_config{'ESX'}{'CREDENTIALS'}{'USERNAME'};
     my $esx_password = $drbc_config{'ESX'}{'CREDENTIALS'}{'PASSWORD'};

     # Work only with ESX hosts in selected datacenter
     if ($esx_datacenter_name ne $datacenter_name) {
	     &debug("ESX is not in right datacenter ... very strange.");
	     next;
     }

     &debug("ESX name: $esx",10);
     &debug("ESX datacenter name: $esx_datacenter_name",10);
     &debug("ESX hostname: $esx_hostname",10);
     &debug("ESX ip: $esx_ip",10);

     my $esx_soap_url = 'https://' . $esx_hostname . '/sdk/webService';
     &debug ("URL of VMware ESX SOAP server (redefined from config): $esx_soap_url",1);
     Opts::set_option('url', $esx_soap_url );
     Opts::set_option('username', $esx_username );
     Opts::set_option('password', $esx_password );

     # Connect to URL (ESX)
     if (!&vi_connect_to_url()) {
	     &debug("Connection to ESX hostname has been unsuccesfull ... try connect to ESX IP ...");
             $esx_soap_url = 'https://' . $esx_ip . '/sdk/webService';
             &debug ("URL of VMware ESX SOAP server (redefined from config): $esx_soap_url",1);
     	     Opts::set_option('url', $esx_soap_url );
	     if (!&vi_connect_to_url()) {
	        &debug("Connection to ESX IP has been unsuccesfull ... try next ESX host");
		next;
	     }
     }


     my %filter = (); 
     $filter{'name'} = $server;
     my $vm_view = Vim::find_entity_view(view_type => 'VirtualMachine',
                                             filter => \%filter);
     unless ($vm_view) {
         &debug("Virtual Machine $server not found.");
         # Disconnect from URL (ESX)
         &vi_disconnect_from_url();
         next;
     }

     my $vm_is_replicated = &in_array($vm_view->name,&get_replicated_servers());
     my $vm_powerstate=$vm_view->runtime->powerState->val;
 
     my $vm_tools_status="unknown";
     if ($vm_view->guest) {
        if ($vm_view->guest->toolsStatus) {
          $vm_tools_status=$vm_view->guest->toolsStatus->val;
        }
     }
     my $vm_action_msg = "";

     &debug( "****************************");
     &debug( "SERVER NAME : " . $server );
     &debug( "DATACENTER : " . $datacenter_name );
     &debug( "VM NAME    : " . $vm_view->name );
     &debug( "VM IS REPLICATED FROM PS TO BS? (0..no, 1..yes): " . $vm_is_replicated );
     &debug( "VM POWER STATE: " . $vm_powerstate );
     &debug( "VM TOOLS STATUS: " . $vm_tools_status );
     &debug("****************************");

     # RELOCATE VM INTO STANDBY NETWORK
     if ( ($vm_is_replicated) && ($params{to_network} eq "standby") ) {
		&debug("Setting NICs to standby network.");
       		&set_nics_to_standby_network($vm_view);
     }
     # END RELOCATE VM INTO STANDBY NETWORK

     # RELOCATE VM INTO APPROPRIATE NETWORKS
     if ( ($vm_is_replicated) && ($params{to_network} eq "appropriate") ) {
		&debug("Setting NICs to appropriate networks.");
       		&set_nics_to_appropriate_networks($vm_view);
     }
     # END RELOCATE VM INTO APPROPRIATE NETWORK

     &debug("VM ACTION: $vm_action_msg");
     &debug("****************************");

  }
  # END -  RELOCATE SERVERS INTO NETWORKS

  return 1;
}
# Function End

#############################################################
# Relocate Servers into STANDBY/APPROPRIATE Network/s
#   &relocate_servers_into_network ( in_datacenter => "backup", to_network => "standby" )
#   &relocate_servers_into_network ( in_datacenter => "backup", to_network => "appropriate" )
#   &relocate_servers_into_network ( in_datacenter => "primary", to_network => "standby" )
#   &relocate_servers_into_network ( in_datacenter => "primary", to_network => "appropriate" )
#
#   Return: 0/1 ... fail/success
############################################################# 
sub relocate_servers_into_network {
  my %params = @_;

  # Connect to URL (VC SOAP Server)
  if (!&vi_connect_to_url()) {
	  return 0;
  }

  # Check parameter - to_network
  if ($params{to_network} eq "standby") {
	  &debug("Relocate servers into STANDBY network");
  } elsif ($params{to_network} eq "appropriate") {
	  &debug("Relocate servers into APPROPRIATE network");
  } else {
	  &debug("Parameter 'to_network' must be STANDBY or APPROPRIATE");
	  # Disconnect from URL (VC SOAP Server)
	  &vi_disconnect_from_url();
	  return 0;
  }

  # Check parameter - in_datacenter
  my $datacenter_view;
  my $datacenter_name;
  if ($params{in_datacenter} eq "backup") {
  	  $datacenter_name = &get_backup_datacenter();
	  &debug("Relocate servers in BACKUP datacenter: $datacenter_name");
	  $datacenter_view = Vim::find_entity_view(view_type => 'Datacenter',
			   filter => { 'name' => $datacenter_name } );
  } elsif ($params{in_datacenter} eq "primary") {
  	  $datacenter_name = &get_primary_datacenter();
	  &debug("Relocate servers in PRIMARY datacenter: $datacenter_name");
	  $datacenter_view = Vim::find_entity_view(view_type => 'Datacenter',
			   filter => { 'name' => $datacenter_name } );
  } else {
	  &debug("Parameter 'in_datacenter' must be PRIMARY or BACKUP");
	  # Disconnect from URL (VC SOAP Server)
	  &vi_disconnect_from_url();
	  return 0;
  }

  &Fail ("Datacenter $datacenter_name not found.") unless ($datacenter_view);

  my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine',
                           begin_entity => $datacenter_view);

  foreach (@$vm_views) {
     my $vm_view=$_;

     my $vm_in_standby_network = &in_array(&get_standby_network(),&vm_get_networks($vm_view));
     my $vm_is_replicated = &in_array($vm_view->name,&get_replicated_servers());
     my $vm_powerstate=$vm_view->runtime->powerState->val;
 
     my $vm_tools_status="unknown";
     if ($vm_view->guest) {
        if ($vm_view->guest->toolsStatus) {
          $vm_tools_status=$vm_view->guest->toolsStatus->val;
        }
     }
     my $vm_action_msg = "";

     &debug("****************************");
     &debug("DATACENTER : " . $datacenter_name );
     &debug("VM NAME    : " . $vm_view->name );
     &debug("VM NETWORKS: " . join(",",&vm_get_networks($vm_view)) );
     &debug("VM IS CONNECTED TO STANDBY NETWORK? (0..no, 1..yes): " . $vm_in_standby_network );
     &debug("VM IS REPLICATED FROM PS TO BS? (0..no, 1..yes): " . $vm_is_replicated );
     &debug("VM POWER STATE: " . $vm_powerstate );
     &debug("VM TOOLS STATUS: " . $vm_tools_status );
 
     # RELOCATE VM INTO STANDBY NETWORK
     if ( ($vm_is_replicated) && ($params{to_network} eq "standby") ) {
		&debug("Setting NICs to standby network.");
       		&set_nics_to_standby_network($vm_view);
     }
     # END RELOCATE VM INTO STANDBY NETWORK

     # RELOCATE VM INTO APPROPRIATE NETWORKS
     if ( ($vm_is_replicated) && ($params{to_network} eq "appropriate") ) {
		&debug("Setting NICs to appropriate networks.");
       		&set_nics_to_appropriate_networks($vm_view);
     }
     # END RELOCATE VM INTO APPROPRIATE NETWORK

     &debug("VM ACTION: $vm_action_msg");
     &debug("****************************");
  }

  # Disconnect from URL (VC SOAP Server)
  &vi_disconnect_from_url();

  return 1;
}
# Function End

#############################################################
# Relocate Standby Servers into STANDBY Resource Pool
#   It checks if it's replicated server connected in standby network
#   It works just in Backup Site Datacenter
############################################################# 
sub relocate_standby_servers_into_standby_pool {

  # Connect to URL (VC SOAP Server)
  if (!&vi_connect_to_url()) {
	  return 0;
  }

  my $datacenter_view = Vim::find_entity_view(view_type => 'Datacenter',
                           filter => { 'name' => &get_backup_datacenter()} );
  &Fail ("Datacenter " . &get_backup_datacenter() . " not found.") unless ($datacenter_view);

  my %drbc_config = &getConfig();
  my $STANDBY_POOL = &get_standby_resource_pool();
  my $pool_view = Vim::find_entity_view(view_type => 'ResourcePool',
                           filter => { 'name' => $STANDBY_POOL} );
  &Fail ("ResourcePool $STANDBY_POOL not found.") unless ($pool_view);

  my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine',
                           begin_entity => $datacenter_view);

  foreach (@$vm_views) {
     my $vm_view=$_;

     my $vm_in_standby_network = &in_array(&get_standby_network(),&vm_get_networks($vm_view));
     my $vm_is_replicated = &in_array($vm_view->name,&get_replicated_servers());
     my $vm_powerstate=$vm_view->runtime->powerState->val;
 
     my $vm_tools_status="unknown";
     if ($vm_view->guest) {
        if ($vm_view->guest->toolsStatus) {
          $vm_tools_status=$vm_view->guest->toolsStatus->val;
        }
     }
     my $vm_action_msg = "";

     &debug("****************************");
     &debug("DATACENTER : " . &get_backup_datacenter() );
     &debug("VM NAME    : " . $vm_view->name );
     &debug("VM NETWORKS: " . join(",",&vm_get_networks($vm_view)) );
     &debug("VM IS CONNECTED TO STANDBY NETWORK? (0..no, 1..yes): " . $vm_in_standby_network );
     &debug("VM IS REPLICATED FROM PS TO BS? (0..no, 1..yes): " . $vm_is_replicated );
     &debug("VM POWER STATE: " . $vm_powerstate );
     &debug("VM TOOLS STATUS: " . $vm_tools_status );
  
     # RELOCATE VM INTO RESOURCE POOL - STANDBY
     if ( ($vm_is_replicated) && ($vm_in_standby_network) ) {

       # TRY RELOCATE
	 $vm_action_msg .= " relocating VM into standby pool ...";
         my $relocate_spec = VirtualMachineRelocateSpec->new(
                                          pool => $pool_view);
	 
         eval {$vm_view->RelocateVM(spec => $relocate_spec);};
         if ($@) {
           my $server_fault=$@;
           my $log_msg = " relocating was unsuccessfull (" . $server_fault. ")";
           $vm_action_msg .= $log_msg;
	   &debug($log_msg);
         }
       # END TRY RELOCATE
     }
     # END RELOCATE VM INTO RESOURCE POOL - STANDBY

     &debug("VM ACTION: $vm_action_msg");
     &debug("****************************");
  }

  # Disconnect from URL (VC SOAP Server)
  &vi_disconnect_from_url();

  return 1;
}
# Function End

#############################################################
# Shutdown/PowerOff Replicated VM in DR Site/Standby Network 
#   It checks if it's replicated server connected in standby network
#   It works just in Backup Site Datacenter
############################################################# 
sub shutdown_standby_servers {

  # Connect to URL (VC SOAP Server)
  if (!&vi_connect_to_url()) {
	  return 0;
  }

  my $datacenter_view = Vim::find_entity_view(view_type => 'Datacenter',
                           filter => { 'name' => &get_backup_datacenter()} );

  &Fail ("Datacenter " . &get_backup_datacenter()  . "not found.") unless ($datacenter_view);

  my %drbc_config = &getConfig();

  my @servers = split(/ /, $drbc_config{'DRBC'}{'SERVER_SHUTDOWN_ORDER'});

  foreach (@servers) {
     my $server=$_; # server name
    
     my %filter = (); 
     $filter{'name'} = $server;
     my $vm_view = Vim::find_entity_view(view_type => 'VirtualMachine',
                                             begin_entity => $datacenter_view,
                                             filter => \%filter);
     unless ($vm_view) {
         &debug("Virtual Machine $server not found.");
         next;
     }

     my $server_fault;
     my $log_msg;
     my $vm_in_standby_network = &in_array(&get_standby_network(),&vm_get_networks($vm_view));
     my $vm_is_replicated = &in_array($vm_view->name,&get_replicated_servers());
     my $vm_powerstate=$vm_view->runtime->powerState->val;
 
     my $vm_tools_status="unknown";
     if ($vm_view->guest) {
        if ($vm_view->guest->toolsStatus) {
          $vm_tools_status=$vm_view->guest->toolsStatus->val;
        }
     }
     my $vm_action_msg = "";

     &debug( "****************************");
     &debug( "DATACENTER : " . &get_backup_datacenter() );
     &debug( "VM NAME    : " . $vm_view->name );
     &debug( "VM NETWORKS: " . join(",",&vm_get_networks($vm_view)) );
     &debug( "VM IS CONNECTED TO STANDBY NETWORK? (0..no, 1..yes): " . $vm_in_standby_network );
     &debug( "VM POWER STATE: " . $vm_powerstate );
     &debug( "VM TOOLS STATUS: " . $vm_tools_status );
  
     # SHUTDOWN/POWEROFF & optionaly UNREGISTER 
     if ( $vm_in_standby_network ) {

	# TRY SHUTDOWN OTHERWISE POWEROFF     
	if ( $vm_powerstate eq "poweredOn") {
	       if (uc($vm_tools_status) eq uc("toolsOK")) {
		 $vm_action_msg.="Shuting down this virtual machine ...";
	       
		 # START EVAL SHUTDOWNGUEST
       		 &debug("Shutting down VM ...");
		 eval {$vm_view->ShutdownGuest();};
		 if ($@) {
		   $server_fault=$@;
		   $log_msg = " shuting down was unsuccessfull (" . $server_fault. ") ... let's Power Off ...";
		   $vm_action_msg .= $log_msg;
		   &debug($log_msg);
		   $vm_view->PowerOffVM();  
		 }

		 # END EVAL SHUTDOWNGUEST
	       } else {
		 $vm_action_msg .= "Power Off this virtual machine ...";
		 eval {$vm_view->PowerOffVM();}
	       }
       }
       
       if ($option_sleep_interval>0) {
       	  &debug("Sleep for $option_sleep_interval seconds ...");
	  sleep($option_sleep_interval);
       }
       # END TRY SHUTDOWN OTHERWISE POWEROFF

       # START TRY WAIT FOR POWERED OFF
       if ($option_wait_for_powered_off) {
	 # Wait for poweredOff state of VM
	 if (not &vm_wait_for_poweredOff($vm_view,300)) {
	   &debug("Unseccesfull waiting for powered off state of this virtual machine ...");
	   &debug("Power Off this virtual machine manualy...");
	   eval {$vm_view->PowerOffVM();}
	 }
       }
       # END TRY WAIT FOR POWERED OFF

       # TRY REMOVE RDM
       if ($option_remove_rdm) {
        
	 # Wait for poweredOff state of VM otherwise power it off manualy
	 if (not &vm_wait_for_poweredOff($vm_view,300)) {
	   &debug("Power Off this virtual machine manualy...");
	   eval {$vm_view->PowerOffVM();}
	 }

	 # Now try remove RDM disks
	 if (&remove_rdm_disks($vm_view)) {;
	   $vm_action_msg .= " If RDM disks existed they have been removed...";
         }
       }
       # END TRY REMOVE RDM

       # TRY ADD RDM
       if ($option_add_rdm) {
	 if (&add_rdm_disks($vm_view)) {;
	   $vm_action_msg .= "... adding RDM disks passed ...";
         }
       }
       # END TRY ADD RDM
       #
       # TRY UNREGISTER
       if ($option_unregister) {
	 # Wait for poweredOff state of VM otherwise power it off manualy
	 if (not &vm_wait_for_poweredOff($vm_view,300)) {
	   &debug("Power Off this virtual machine manualy...");
	   eval {$vm_view->PowerOffVM();}
	 }

	 $vm_action_msg .= " unregistering VM ...";
         eval {$vm_view->UnregisterVM();};
         if ($@) {
           $server_fault=$@;
           $log_msg = " unregistering has been unsuccessfull (" . $server_fault. ")";
	   $vm_action_msg .= $log_msg;
	   &debug($log_msg);
         }
       }
       # END TRY UNREGISTER

       # TRY DELETE FROM DISK
       if ($option_deletefromdisk) {
	 # Wait for poweredOff state of VM otherwise power it off manualy
	 if (not &vm_wait_for_poweredOff($vm_view,300)) {
	   &debug("Power Off this virtual machine manualy...");
	   eval {$vm_view->PowerOffVM();}
	 }

	 $vm_action_msg .= " deleting VM from disk ...";
         eval {
	 	&debug("Destroying virtual machine (unregister & delete from disk) ...");
		$vm_view->Destroy();
	 };
         if ($@) {
           $server_fault=$@;
           $log_msg = " delete has been unsuccessfull (" . $server_fault. ")";
	   $vm_action_msg .= $log_msg;
	   &debug($log_msg);
         }
       }
       # END TRY DELETE FROM DISK

     }
     # END SHUTDOWN/POWEROFF & optionaly UNREGISTER

     &debug("VM ACTION: $vm_action_msg");
     &debug("****************************");
  }

  # Disconnect from URL (VC SOAP Server)
  &vi_disconnect_from_url();

  return 1;
}
# Function End

#############################################################
# Start Replicated VM in DR Site/Standby Network 
#   It checks if it's replicated server connected in standby network
#   It works just in Backup Site Datacenter
############################################################# 
sub start_standby_servers {
  # Connect to URL (VC SOAP Server)
  if (!&vi_connect_to_url()) {
	  return 0;
  }

  my $datacenter_view = Vim::find_entity_view(view_type => 'Datacenter',
                           filter => { 'name' => &get_backup_datacenter()} );

  &Fail ("Datacenter " . &get_backup_datacenter()  . "not found.") unless ($datacenter_view);

  my %drbc_config = &getConfig();

  my @servers = split(/ /, $drbc_config{'DRBC'}{'SERVER_STARTUP_ORDER'});

  foreach (@servers) {
     my $server=$_; # server name
    
     my %filter = (); 
     $filter{'name'} = $server;
     my $vm_view = Vim::find_entity_view(view_type => 'VirtualMachine',
                                             begin_entity => $datacenter_view,
                                             filter => \%filter);
     unless ($vm_view) {
         &debug("Virtual Machine $server not found.");
         next;
     }

     my $vm_in_standby_network = &in_array(&get_standby_network(),&vm_get_networks($vm_view));
     my $vm_is_replicated = &in_array($vm_view->name,&get_replicated_servers());
     my $vm_powerstate=$vm_view->runtime->powerState->val;
 
     my $vm_tools_status="unknown";
     if ($vm_view->guest) {
        if ($vm_view->guest->toolsStatus) {
          $vm_tools_status=$vm_view->guest->toolsStatus->val;
        }
     }
     my $vm_action_msg = "";
     my $vmname = $vm_view->name;

     &debug( "****************************");
     &debug( "STANDBY SERVER NAME : " . $server );
     &debug( "DATACENTER : " . &get_backup_datacenter() );
     &debug( "VM NAME    : " . $vmname );
     &debug( "VM NETWORKS: " . join(",",&vm_get_networks($vm_view)) );
     &debug( "VM IS CONNECTED TO STANDBY NETWORK? (0..no, 1..yes): " . $vm_in_standby_network );
     &debug( "VM IS REPLICATED FROM PS TO BS? (0..no, 1..yes): " . $vm_is_replicated );
     &debug( "VM POWER STATE: " . $vm_powerstate );
     &debug( "VM TOOLS STATUS: " . $vm_tools_status );
     &debug("****************************");

     #TESTS BEFORE POWERON
     &pre_post_tests(vmname => $vmname, type => 'BEFORE_POWER_ON');

     # START - POWERON STANDBY SERVER
     if ( ($vm_is_replicated) && ($vm_in_standby_network) && ($vm_powerstate ne 'poweredOn') ) {

	&debug("Starting virtual machine ...");
	$vm_action_msg = "PowerOn VM";
	
	my $vm_poweron_task;
	$vm_poweron_task = $vm_view->PowerOnVM_Task();
	 
	# CHECK IF POWERON IS SUCCESSFULL

	my $curr_state="running";
	my $rotation = 0;
	do
	{
		sleep(15);
		my $my_vm = Vim::get_view(mo_ref => $vm_poweron_task);
		$curr_state=$my_vm->info->state->val;
		$rotation=$rotation+1;
		&debug(" ... current state: " . $curr_state . " ... (rotation $rotation) waiting 15 sec.");

		&AnswerVMQuestionWithDefaultAnswer(vmname => $vm_view->name, datacenter => &get_backup_datacenter() );
	}
	until( ($curr_state eq 'success')  || ($curr_state eq 'error') ); 

     	if ($curr_state ne 'success') {
    		&debug("PowerOn Task failed with state: $curr_state");
     	} else {
		&debug("PowerOn has been successfull.");
     	}

     }
     # END - POWERON STANDBY SERVER

     #TESTS AFTER POWERON
     &pre_post_tests(vmname => $vmname, type => 'AFTER_POWER_ON');

     &debug("VM ACTION: $vm_action_msg");
     &debug("****************************");

  }

  # Disconnect from URL (VC SOAP Server)
  &vi_disconnect_from_url();

  return 1;
}
# Function End

#############################################################
# Check primary servers if exist snapshot
#   &check_primary_servers_if_exist_snapshot ( in_datacenter => "backup" )
#   &check_primary_servers_if_exist_snapshot ( in_datacenter => "primary" )
#
#   Return: 0/1 ... fail/success
############################################################# 
sub check_primary_servers_if_exist_snapshot {
  my %params = @_;

  # Connect to URL (VC SOAP Server)
  if (!&vi_connect_to_url()) {
	  return 0;
  }

  # Check parameter - in_datacenter
  my $datacenter_view;
  my $datacenter_name;
  if ($params{in_datacenter} eq "backup") {
  	  $datacenter_name = &get_backup_datacenter();
	  &debug("Relocate servers in BACKUP datacenter: $datacenter_name");
	  $datacenter_view = Vim::find_entity_view(view_type => 'Datacenter',
			   filter => { 'name' => $datacenter_name } );
  } elsif ($params{in_datacenter} eq "primary") {
  	  $datacenter_name = &get_primary_datacenter();
	  &debug("Relocate servers in PRIMARY datacenter: $datacenter_name");
	  $datacenter_view = Vim::find_entity_view(view_type => 'Datacenter',
			   filter => { 'name' => $datacenter_name } );
  } else {
	  &debug("Parameter 'in_datacenter' must be PRIMARY or BACKUP");
	  # Disconnect from URL (VC SOAP Server)
	  &vi_disconnect_from_url();
	  return 0;
  }

  &Fail ("Datacenter $datacenter_name not found.") unless ($datacenter_view);

  my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine',
                           begin_entity => $datacenter_view);

  my @servers = split(/ /, $drbc_config{'DRBC'}{'SERVER_CHECK_IF_EXIST_SNAPSHOT'});
  my $servers_with_snapshot = "";

  foreach (@$vm_views) {
     my $vm_view=$_;

     my $vm_in_standby_network = &in_array(&get_standby_network(),&vm_get_networks($vm_view));
     my $vm_is_replicated = &in_array($vm_view->name,&get_replicated_servers());
     my $vm_check_snapshot = &in_array($vm_view->name,@servers);
     my $vm_powerstate=$vm_view->runtime->powerState->val;
 
     my $vm_tools_status="unknown";
     if ($vm_view->guest) {
        if ($vm_view->guest->toolsStatus) {
          $vm_tools_status=$vm_view->guest->toolsStatus->val;
        }
     }
     my $vm_action_msg = "";

     &debug("****************************");
     &debug("DATACENTER : " . $datacenter_name );
     &debug("VM NAME    : " . $vm_view->name );
     &debug("VM NETWORKS: " . join(",",&vm_get_networks($vm_view)) );
     &debug("VM IS CONNECTED TO STANDBY NETWORK? (0..no, 1..yes): " . $vm_in_standby_network );
     &debug("VM IS REPLICATED FROM PS TO BS? (0..no, 1..yes): " . $vm_is_replicated );
     &debug("VM CHECK SNAPSHOT? (0..no, 1..yes): " . $vm_check_snapshot );
     &debug("VM POWER STATE: " . $vm_powerstate );
     &debug("VM TOOLS STATUS: " . $vm_tools_status );
 
     if ($vm_check_snapshot) {
	&debug("Check if virtual machine has snapshot ...");
	$vm_action_msg = "Check VM snapshot";

	if ($vm_view->snapshot) {
		&debug("VM has snapshot");
  		$servers_with_snapshot .= $vm_view->name . " ";
		$ERROR_LEVEL = 1;
	} else {
		&debug("VM hasn't snapshot");
	}
     }

     &debug("VM ACTION: $vm_action_msg");
     &debug("****************************");
  }

  # Disconnect from URL (VC SOAP Server)
  &vi_disconnect_from_url();

  if ($ERROR_LEVEL != 0) {
	# notify admin by email
	my $message = "Some primary servers ($servers_with_snapshot) have snapshots and vRanger cannot backup.";
        &debug("!!! $message !!!");
	&mailNotify(subject=> "DRBC/DRBC.PL", message=>$message);
  }

  return 1;
}
# Function End

# ****************************************************************
# ****************************************************************
#   SUPPORTING FUNCTIONS
# ****************************************************************
# ****************************************************************


#############################################################
# Check what VM's are on which ESX host
# Parameters:
#   datacenter - Datacenter Name
#   example: CheckWhatVmsAreOnWhichEsx(datacenter => "Bardosova")
# Return: hash of VM and ESX servers where VM is located
#    %vm_esx = (); # $vm_esx{VMNAME} = ESX-HOST; # so for example $vm_esx{LL-DB}='ESX2-BS';
############################################################# 
sub CheckWhatVmsAreOnWhichEsx {
  my %params = @_;

  my $datacenter_name = $params{datacenter};
  my %drbc_config = &getConfig();

  # Traverse all ESX's in datacenter (primary or backup)
  # $CONFIG{'ESX'}{'HOST'}{'ESX4-BS'}{'DATACENTER'} = "Bardosova";
  # $CONFIG{'DRBC'}{'ESX_SERVERS'} = "ESX1-PS ESX2-PS ESX3-PS ESX4-PS ESX1-BS ESX2-BS ESX3-BS ESX4-BS";
  # $CONFIG{'ESX'}{'CREDENTIALS'}{'USERNAME'} = "root";
  # $CONFIG{'ESX'}{'CREDENTIALS'}{'PASSWORD'} = "password";

  my @esx_servers = split (/ /, $drbc_config{'DRBC'}{'ESX_SERVERS'} );
  my %vm_esx = (); # $vm_esx{VMNAME} = ESX-HOST; # so for example $vm_esx{LL-DB}='ESX2-BS';

  # START - CHECK WHAT VM's ARE ON WHICH ESX
  foreach (@esx_servers) {
	  my $esx = $_;
	  my $esx_datacenter_name = $drbc_config{'ESX'}{'HOST'}{$esx}{'DATACENTER'};
	  my $esx_hostname = $drbc_config{'ESX'}{'HOST'}{$esx}{'HOSTNAME'};
	  my $esx_ip = $drbc_config{'ESX'}{'HOST'}{$esx}{'IP'};
	  my $esx_username = $drbc_config{'ESX'}{'CREDENTIALS'}{'USERNAME'};
	  my $esx_password = $drbc_config{'ESX'}{'CREDENTIALS'}{'PASSWORD'};

	  # Work only with ESX hosts in selected datacenter
	  if ($esx_datacenter_name eq $datacenter_name) {
	  	&debug("ESX name: $esx",10);
	  	&debug("ESX datacenter name: $esx_datacenter_name",10);
	  	&debug("ESX hostname: $esx_hostname",10);
	  	&debug("ESX ip: $esx_ip",10);

		my $esx_soap_url = 'https://' . $esx_hostname . '/sdk/webService';
		&debug ("URL of VMware ESX SOAP server (redefined from config): $esx_soap_url",10);
		Opts::set_option('url', $esx_soap_url );
		Opts::set_option('username', $esx_username );
		Opts::set_option('password', $esx_password );

	        # Connect to URL (ESX)
	        if (!&vi_connect_to_url()) {
		     &debug("Connection to ESX hostname has been unsuccesfull ... try connect to ESX IP ...");
		     $esx_soap_url = 'https://' . $esx_ip . '/sdk/webService';
		     &debug ("URL of VMware ESX SOAP server (redefined from config): $esx_soap_url",1);
		     Opts::set_option('url', $esx_soap_url );
		     if (!&vi_connect_to_url()) {
			&debug("Connection to ESX IP has been unsuccesfull ... try next ESX host");
			next;
		     }
     		}

		# START - go through all VM on this ESX server
		my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine');

		foreach (@$vm_views) {
	             my $vm_view=$_;
		     my $vm_powerstate=$vm_view->runtime->powerState->val;
		 
		     my $vm_tools_status="unknown";
		     if ($vm_view->guest) {
			if ($vm_view->guest->toolsStatus) {
			  $vm_tools_status=$vm_view->guest->toolsStatus->val;
			}
		     }

		     &debug( "****************************",10);
		     &debug( "VM NAME    : " . $vm_view->name ,10);
		     &debug( "VM POWER STATE: " . $vm_powerstate ,10);
		     &debug( "VM TOOLS STATUS: " . $vm_tools_status,10);
		     &debug("****************************",10);

		     # store in which ESX server is this VM
		     $vm_esx{$vm_view->name}=$esx;
		     &debug( "VM NAME: " . $vm_view->name . " ($esx)");
		}

		# END - go through all VM on this ESX server
	  
		# Disconnect from URL (ESX)
	  	&vi_disconnect_from_url();
  	  }

  }
  # END - CHECK WHAT VM's ARE ON WHICH ESX

  return %vm_esx;
}


#############################################################
# Answer VM Question with Default Answer
# Parameters:
#   vmname - Virtual Machine Name
#   datacenter - Datacenter Name
#   example: AnswerVMQuestionWithDefaultAnswer(vmname => "LL-DB", datacenter => "Bardosova")
# Return: 0/1 = false/true
############################################################# 
sub AnswerVMQuestionWithDefaultAnswer {
	my %params = @_;

	&debug("Answer VM Question - if any - with default answer.");

	if (!$params{vmname}) {
		&debug("vmname is not defined.");
	}

  	my $datacenter_view;
	if (!$params{datacenter}) {
		&debug("datacenter is not defined.");
		# session is probably connected directly to ESX server instead to VC 
		# go ahead but don't search in datacenter
	} else {
  		$datacenter_view = Vim::find_entity_view(view_type => 'Datacenter',
                           filter => { 'name' => $params{datacenter} } );
		if (!$datacenter_view) {
 			&Debug("Datacenter " . $params{datacenter} . "not found.");
			return 0;
		}
	}

	my %filter = (); 
	$filter{'name'} = $params{vmname};
	
	my $vm_view;
	if ($datacenter_view) {
		$vm_view = Vim::find_entity_view(view_type => 'VirtualMachine',
                                             begin_entity => $datacenter_view,
                                             filter => \%filter);
		&debug("Datacenter: " . $datacenter_view->name);
	} else {
		$vm_view = Vim::find_entity_view(view_type => 'VirtualMachine',
                                             filter => \%filter);
	}
	
	unless ($vm_view) {
		&debug("Virtual Machine " . $params{vmname} . " not found.");
		return 0;
	}

	&debug("Virtual machine: " . $vm_view->name);
	
	# START ANSWER KEEP UUID
	if (defined ($vm_view->runtime->question)) {
		&debug("Runtime->Question is defined.");
	}

	if (defined ($vm_view->runtime->question) && defined($vm_view->runtime->question->id)) {
		&debug("Keeping VM UUID for " . $vm_view->config->name );
		$vm_view->AnswerVM(questionId => $vm_view->runtime->question->id, answerChoice => $vm_view->runtime->question->choice->defaultIndex);
		
	}
	# END ANSWER KEEP ID
	
	return 1;
}
# Function End

#############################################################
# Add RDM disks to VM
# Parameters:
#   vm - Virtual Machine reference
# Return: 0/1 = false/true
############################################################# 
sub add_rdm_disks {
  my ($vm_view) = @_;

  my $vm_name=$vm_view->name;
  my %drbc_config = &getConfig();

  for (my $i=1; $i<100; $i++) {
    if (($drbc_config{'SERVER'}{$vm_name}{'RDM'}{$i}{'NAME'}) &&
        ($drbc_config{'SERVER'}{$vm_name}{'RDM'}{$i}{'EMC_LUN_ID'}) ) {

       my $disk_name = $drbc_config{'SERVER'}{$vm_name}{'RDM'}{$i}{'NAME'};
       my $emc_lun_id = $drbc_config{'SERVER'}{$vm_name}{'RDM'}{$i}{'EMC_LUN_ID'};
       my $esx_lun_id = $drbc_config{'SERVER'}{$vm_name}{'RDM'}{$i}{'ESX_LUN_ID'};
       my $scsi_bus_id = $drbc_config{'SERVER'}{$vm_name}{'RDM'}{$i}{'SCSI_BUS_ID'};

       &debug("-----------------------------------------------------------------");
       &debug("Adding RDM disk" .  " Name: " . $disk_name .  " EMC LUN ID: " . $emc_lun_id . " ESX LUN ID: ". $esx_lun_id);

       # START SCAN AVAILABLE VMWARE LUNs ON MY DATASTORE 
       my $host_view = Vim::get_view( mo_ref => $vm_view->runtime->host); 
       my $dsSys = Vim::get_view( mo_ref => $host_view->configManager->datastoreSystem ); 
       my $available_luns = $dsSys->QueryAvailableDisksForVmfs();
       &debug("Available vmware LUNs ...");
       
       my $lun;   # LUN Managed Object for use to RDM
       my $lun_i; # only temporary for cyclus bellow
       foreach $lun_i (@$available_luns) {
	 &debug("Lun: " . $lun_i->canonicalName);
	 my ($hba,$sp,$lunid) = split(/:/,$lun_i->canonicalName);
	 if ($lunid == $esx_lun_id) {
           $lun=$lun_i;
	 }
       }

       if ($scsi_bus_id) {
       } else {
         &debug("SCSI BUS ID is not defined in config file");
       }
       
       if ($lun) {
       } else {
           &debug("Drive hasn't been found on ESX host");
       }

       if ( ($scsi_bus_id) && ($lun) ) {
           &debug("Drive has been found: ". $lun->canonicalName);

	       # START ADD RDM DISK
	       my $datastore = Vim::get_view( mo_ref => $vm_view->datastore->[0]);
	       &debug("Use datastore: ". $datastore->summary->name);

	       my $filename = $vm_name . "_" . $esx_lun_id . "_rdm";
	       my $full_filename = VMUtils::generate_filename(
				       vm => $vm_view,
				       filename => $filename);

	       my $device_name = $lun->canonicalName . ':0';
	       my $lun_uuid = $lun->uuid;
	       my $lun_device_path = $lun->devicePath;
               my $lun_capacityInKB = $lun->{capacity}{block}/2;

	       &debug("Use filename: ". $full_filename);
	       &debug("Device name: ". $device_name);
	       &debug("LUN UUID: ". $lun_uuid);
	       &debug("LUN Device Path: ". $lun_device_path);
	       &debug("SCSI BUS ID: ". $scsi_bus_id);
	       &debug("LUN capacityInKB: ". $lun_capacityInKB);

	       my $disk_backing_info =
		 VirtualDiskRawDiskMappingVer1BackingInfo->new(
		   compatibilityMode => 'physicalMode',
		   deviceName => $lun_device_path,
		   lunUuid => $lun_uuid,
		   diskMode => 'independent_persistent',
		   fileName => $full_filename
		 );

	       my $controller = 
		 VMUtils::find_device(
		   vm => $vm_view,
		   controller => 'SCSI Controller 0'
		 );

	       # Assign SCSI bus number
	       my $unit_number = $scsi_bus_id;
	       &debug("Device unit number (SCSI BUS ID): ". $unit_number);

	       my $disk = 
		 VirtualDisk->new(
		   controllerKey => $controller->key,
		   unitNumber => $unit_number,
		   backing => $disk_backing_info,
                   capacityInKB => $lun_capacityInKB,
		   key => -1
		 );
	       
               my $devspec = 
	         VirtualDeviceConfigSpec->new(operation => VirtualDeviceConfigSpecOperation->new('add'),
                                              device => $disk,
                                              fileOperation => VirtualDeviceConfigSpecFileOperation->new('create'));

	       my $vmspec = VirtualMachineConfigSpec->new(deviceChange => [$devspec] );

		# RECONFIGURE VM
		   eval {
		      &debug("Virtual machine '" . $vm_view->name . "' adding RDM disk.");
		      $vm_view->ReconfigVM( spec => $vmspec );
		      &debug("Virtual machine '" . $vm_view->name . "' has been added absolutely successfully.");
		   };
		   if ($@) {
		       &debug("Reconfiguration failed:");
		       if (ref($@) eq 'SoapFault') {
			  if (ref($@->detail) eq 'TooManyDevices') {
			     &debug("Number of virtual devices exceeds the maximum for a given controller.");
			  }
			  elsif (ref($@->detail) eq 'InvalidDeviceSpec') {
			     &debug("The Device configuration is not valid. Following is the detailed error: \n\n$@");
			  }
			  elsif (ref($@->detail) eq 'FileAlreadyExists') {
			     &debug("Operation failed because file already exists");
			  }
			  else {
			     &debug($@);
			  }
		       }
		       else {
			  &debug($@);
		       }
		   }
		# END RECONFIGURE VM

               # END ADD RDM DISK

       } 
       # END SCAN AVAILABLE VMWARE LUNs ON MY DATASTORE 

    }
  }

  return 1;
}

#############################################################
# Remove RDM disks from VM
# Parameters:
#   vm - Virtual Machine reference
# Return: 0/1 = false/true
############################################################# 
sub remove_rdm_disks {
  my ($vm_view) = @_;

  my %drbc_config = &getConfig();

  my $devices = $vm_view->config->hardware->device;
  foreach my $dev (@$devices) {
    if (ref($dev) eq "VirtualDisk") {
      my $disk_name = $dev->deviceInfo->label;
      my $disk_emc_lun_id = &get_emclunid_from_config($vm_view->name,$disk_name);
      if ($disk_emc_lun_id) {
        printf ("%-20.20s %4d %-40.40s\n", $disk_name, $disk_emc_lun_id, ref($dev));

        my ($config_spec_operation, $config_file_operation);
        $config_spec_operation = VirtualDeviceConfigSpecOperation->new('remove');
        $config_file_operation = VirtualDeviceConfigSpecFileOperation->new('destroy');

        my $device_spec =
         VirtualDeviceConfigSpec->new(operation => $config_spec_operation,
                                      device => $dev,
                                      fileOperation => $config_file_operation);

	my @device_config_specs = ();
        push(@device_config_specs, $device_spec);
	my $vmspec = VirtualMachineConfigSpec->new(deviceChange => \@device_config_specs);

        # RECONFIGURE VM
	   eval {
	      &debug("Virtual machine '" . $vm_view->name . "' removing RDM disk $disk_name ($disk_emc_lun_id)");
	      $vm_view->ReconfigVM( spec => $vmspec );
	      &debug("Virtual machine '" . $vm_view->name . "' is reconfigured absolutely successfully.");
	   };
	   if ($@) {
	       &debug("Reconfiguration failed:");
	       if (ref($@) eq 'SoapFault') {
		  if (ref($@->detail) eq 'TooManyDevices') {
	             &debug("Number of virtual devices exceeds the maximum for a given controller.");
		  }
		  elsif (ref($@->detail) eq 'InvalidDeviceSpec') {
		     &debug("The Device configuration is not valid. Following is the detailed error: \n\n$@");
		  }
		  elsif (ref($@->detail) eq 'FileAlreadyExists') {
		     &debug("Operation failed because file already exists");
		  }
		  else {
		     &debug($@);
		  }
	       }
	       else {
		  &debug($@);
	       }
	   }
	# END RECONFIGURE VM
      }
    }
  }

  return 1;
}

#############################################################
# Set all VM NICs to appropriate VLANs
# Parameters:
#   vm - Virtual Machine reference
# Return: 0/1 = false/true
############################################################# 
sub set_nics_to_appropriate_networks {
  my ($vm_view) = @_;

  my %drbc_config = &getConfig();

  my $devices = $vm_view->config->hardware->device;
  foreach my $dev (@$devices) {
    if ( (ref($dev) eq "VirtualPCNet32") || (ref($dev) eq "VirtualE1000") ) {
      	my $vm_name = $vm_view->name;
	&debug("VM name: $vm_name");
      	my $nic_name = $dev->deviceInfo->label;
	&debug("NIC name: $nic_name");
	my (undef, undef, $nic_id) = split (/ /, $nic_name); # "Network Adapter 1"
	&debug("NIC id: $nic_id");

	my $nic_device_name = $drbc_config{'SERVER'}{$vm_name}{'NIC'}{$nic_id};
	&debug("NIC deviceName (VLAN NETWORK): $nic_device_name");
	my $nic_device_key = $dev->key;
	&debug("NIC device key: $nic_device_key");

	my $backing_info = VirtualEthernetCardNetworkBackingInfo->new( deviceName => $nic_device_name );

	my $changed_device;
        if (ref($dev) eq "VirtualPCNet32") {
		$changed_device = VirtualPCNet32->new(key => $nic_device_key,
                                    backing => $backing_info);
        }

        if (ref($dev) eq "VirtualE1000") {
		$changed_device = VirtualE1000->new(key => $nic_device_key,
                                    backing => $backing_info);
        }

      	my $config_spec_operation;
      	$config_spec_operation = VirtualDeviceConfigSpecOperation->new('edit');

      	my $device_spec =
         VirtualDeviceConfigSpec->new(operation => $config_spec_operation,
                                      device => $changed_device);

 	my @device_config_specs = ();
        push(@device_config_specs, $device_spec);
	my $vmspec = VirtualMachineConfigSpec->new(deviceChange => \@device_config_specs);

        # RECONFIGURE VM
	   eval {
	      &debug("Virtual machine '" . $vm_view->name . "' changing nic network (vlan) to APPROPRIATE NETWORKs");
	      $vm_view->ReconfigVM( spec => $vmspec );
	      &debug("Virtual machine '" . $vm_view->name . "' is reconfigured absolutely successfully.");
	   };
	   if ($@) {
	       &debug("Reconfiguration failed:");
	       &debug($@);
	   }
	# END RECONFIGURE VM
    }
  }

  return 1;
}

#############################################################
# Set all VM NICs to STANDBY VLAN
# Parameters:
#   vm - Virtual Machine reference
# Return: 0/1 = false/true
############################################################# 
sub set_nics_to_standby_network {
  my ($vm_view) = @_;

  my %drbc_config = &getConfig();

  my $devices = $vm_view->config->hardware->device;
  foreach my $dev (@$devices) {
    if ( (ref($dev) eq "VirtualPCNet32") || (ref($dev) eq "VirtualE1000") ) {
      	my $nic_name = $dev->deviceInfo->label;
	&debug("NIC name: $nic_name");
	my $nic_device_name = &get_standby_network();
	&debug("NIC deviceName (VLAN NETWORK): $nic_device_name");
	my $nic_device_key = $dev->key;
	&debug("NIC device key: $nic_device_key");

	my $backing_info = VirtualEthernetCardNetworkBackingInfo->new( deviceName => $nic_device_name );

	my $changed_device;
        if (ref($dev) eq "VirtualPCNet32") {
		$changed_device = VirtualPCNet32->new(key => $nic_device_key,
                                    backing => $backing_info);
        }

        if (ref($dev) eq "VirtualE1000") {
		$changed_device = VirtualE1000->new(key => $nic_device_key,
                                    backing => $backing_info);
        }

      	my $config_spec_operation;
      	$config_spec_operation = VirtualDeviceConfigSpecOperation->new('edit');

      	my $device_spec =
         VirtualDeviceConfigSpec->new(operation => $config_spec_operation,
                                      device => $changed_device);

 	my @device_config_specs = ();
        push(@device_config_specs, $device_spec);
	my $vmspec = VirtualMachineConfigSpec->new(deviceChange => \@device_config_specs);

        # RECONFIGURE VM
	   eval {
	      &debug("Virtual machine '" . $vm_view->name . "' changing nic network (vlan) to STANDBY NETWORK");
	      $vm_view->ReconfigVM( spec => $vmspec );
	      &debug("Virtual machine '" . $vm_view->name . "' is reconfigured absolutely successfully.");
	   };
	   if ($@) {
	       &debug("Reconfiguration failed:");
	       &debug($@);
	   }
	# END RECONFIGURE VM
    }
  }

  return 1;
}


#############################################################
# Wait for poweredOff status of VM
# Parameters:
#   vm - Virtual Machine reference
#   wait_time - how many second wait?
# Example: &vm_wait_for_powerOff($vm_view,300);  
# Return: 0/1 = false/true  ... true stands for powerOff status
############################################################# 
sub vm_wait_for_poweredOff {
  my ($vm_view, $wait_time) = @_;

  my $refresh_time = 10; # refresh time is 10s
  my $max_i = $wait_time / $refresh_time;
  my $vm_powerstate;

  for (my $i=1; $i<$max_i; $i++) {      
    # Refresh the state of $vm_view
    $vm_view->update_view_data();
    $vm_powerstate=$vm_view->runtime->powerState->val;
    if ($vm_powerstate eq 'poweredOn') {
      &debug("Waiting next 10 seconds (max $wait_time seconds) for poweredOff state (now is $vm_powerstate)");
      sleep(10);
    } else {
      &debug("OK now is Off ($vm_powerstate) ... we can continue");
      last;
    }
  }

  # What is the current vm state
  $vm_view->update_view_data();
  $vm_powerstate=$vm_view->runtime->powerState->val;
  if ($vm_powerstate eq 'poweredOff') {
	  return 1;
  } else {
	  return 0;
  }
}

#############################################################
# Perform pre/post tests
# Parameters:
#   vmname => LL-DB
#   type => AFTER_POWER_ON | BEFORE_POWER_ON
# Return: 0/1 - fail/success
############################################################# 
sub pre_post_tests {
  my %params = @_;

  if (!$params{vmname}) {
	  &debug("Parameter 'vmname' is not defined.");
	  return 0;
  }

  if (!$params{type}) {
	  &debug("Parameter 'type' is not defined.");
	  return 0;
  }

  my $vmname = $params{vmname};
  my $type = $params{type};

  my $tests = $drbc_config{'SERVER'}{$vmname}{'TESTS'}{$type};
  if ( (!$tests) || ($tests eq "") ) {
	  &debug("No " . $params{type} . " tests defined");
	  return 0;
  }

  &debug("Performing " . $params{type} . " tests ...");

  my @tests = split(/ /,$tests);
  foreach my $test (@tests) {
    &debug("  Test: $test");

    if (!$drbc_config{'SERVER'}{$vmname}{'TEST'}{$test}) {
	  &debug("Test is not configured properly.");
	  &fail("Die script with ERROR_LEVEL=1");
    }
    my $cmd = $drbc_config{'SERVER'}{$vmname}{'TEST'}{$test};
    &debug("  Command: $cmd");
    my $error_level = system $cmd;
    if ($error_level != 0 ) {
      &debug("Test has been unsuccessfull. Quit starting servers.");
      &fail("Die script with ERROR_LEVEL=1");
    }
    &debug("  Test has been successfull.");
  }

  return 1;
}

#############################################################
# List standby servers 
# Parameters:
#   no param
# Return: array of virtual machines which are replicated form PS->BS - For example: "{LL-DC,LL-DB,LL-ARCHIVE}" 
############################################################# 
sub list_standby_servers {
  my @servers = &get_replicated_servers();
  &debug("Standby servers: " . join(',',@servers) );  
}
# Function End

#############################################################
# Get Array of Standby (Replicated) VMs names
# Parameters:
#   no param
# Return: array of virtual machines which are replicated form PS->BS - For example: "{LL-DC,LL-DB,LL-ARCHIVE}" 
############################################################# 
sub get_replicated_servers {
  my %drbc_config = &getConfig();
  my @drbc_servers = ();

  while(my($section,$servers_href) = each %drbc_config) {
    	if ($section eq 'SERVER') {	  
	    while(my($server,$host_href) = each %{$servers_href}) {
	      if ($section eq 'SERVER') {
		push(@drbc_servers, $server);
	      }
	    }
    	}
  }

  return @drbc_servers;
}
# Function End

#############################################################
# Get EMC LUN ID from config
# Example: &get_emclunid_from_config('LL_DB','Hard Disk 2')
#############################################################
sub get_emclunid_from_config {
  my ($vm_name, $disk_name) = @_;
  my %drbc_config = &getConfig();
  
  for (my $i=1; $i<100; $i++) {
    if (($drbc_config{'SERVER'}{$vm_name}{'RDM'}{$i}{'NAME'}) &&
        ($drbc_config{'SERVER'}{$vm_name}{'RDM'}{$i}{'NAME'} eq $disk_name) ) {
	    return $drbc_config{'SERVER'}{$vm_name}{'RDM'}{$i}{'EMC_LUN_ID'};
    }
  }

  return 0; # false ... no RDM LUN with this disk name in this VM
}

#############################################################
# Get Network :ames where VM is connected
# Parameters:
#   vm - Virtual Machine reference
# Return: array of network names - For example: "{VI_DEV,VI_STANDBY}" 
# Example: &vm_get_networks($vm_view) 
############################################################# 
sub vm_get_networks {
  my ($vm_view) = @_;

  my @vm_networks = ();

  my $virtual_hardware = $vm_view->config->hardware;
  my $devices = $virtual_hardware->device;
  foreach my $dev (@$devices) {
     if ( (ref($dev) eq "VirtualPCNet32") || (ref($dev) eq "VirtualE1000") ) {
       #VLAN TAG OF THIS NETWORK CARD 
       push(@vm_networks,$dev->backing->deviceName);
     }
  }

  return @vm_networks;
}
# Function End

#############################################################
# Get primary datacenter 
# Parameters:
#   None
# Return: Datacenter name
# Return Example: Bardosova 
############################################################# 
sub get_primary_datacenter {
  my %drbc_config = &getConfig();
  return $drbc_config{'DRBC'}{'PRIMARY_DATACENTER'};
}

#############################################################
# Get datacenter dedicated for disaster
# Parameters:
#   None
# Return: Datacenter name
# Return Example: Bardosova 
############################################################# 
sub get_backup_datacenter {
  my %drbc_config = &getConfig();
  return $drbc_config{'DRBC'}{'BACKUP_DATACENTER'};
}

#############################################################
# Get standby pool for isolated servers
# Parameters:
#   None
# Return: Stanby Resource Pool name
# Return Example: STANDBY
############################################################# 
sub get_standby_resource_pool {
  my %drbc_config = &getConfig();
  return $drbc_config{'DRBC'}{'STANDBY_RESOURCE_POOL'};
}

#############################################################
# Get standby network for isolated servers
# Parameters:
#   None
# Return: Stanby Network Name
# Return Example: STANDBY
############################################################# 
sub get_standby_network {
  my %drbc_config = &getConfig();
  return $drbc_config{'DRBC'}{'STANDBY_NETWORK'};
}

#############################################################
# Search string in array 
# in_array(array,search_text)
############################################################# 
sub in_array {
  my ($search_for,@arr) = @_;
 
  foreach my $item (@arr) {
    if ($item eq $search_for) {
      return 1;
    }
  }

  return 0;  
}
# Function End

#############################################################
# Fail 
# Fail(reason_text_message)
############################################################# 
sub Fail {
  my ($msg) = @_;
  Util::disconnect();
  &debug($msg);
  die ($msg . "\n");
  exit 1;
}

# Mail Notification
# INPUT: params = { 
# 		subject => "DRBC/VRANGER.PL", 
# 		message => "Some backup are not OK.",
# 		}
# OUTPUT: 0/1 .. failure/success
sub mailNotify {
	my %params = @_;
	my %config = &getConfig();


	my $relay=$config{mail_smtp_server};
	my $to=$config{mail_to};
	my $from=$config{mail_from};

	if ( (!$relay) || (!$to) || (!$from) ) {
		&debug("No mail notification.");
		&debug("Mail is not configured ... \$CONFIG{mail_smtp_server,mail_to,mail_from}");
		return 0;
	}

	&debug("Sending mail notification to $to ...");
	my $subject=$params{subject};
	my $message=$params{message};
  
	my $smtp = Net::SMTP->new($relay);
        if (!$smtp) {
		&debug("Cannot connect to smtp server $relay");
	}

	$smtp->mail($from);
	$smtp->to($to);
	$smtp->data();

	# Send the header.
	$smtp->datasend("To: $to\n");
	$smtp->datasend("From: $from\n");
	$smtp->datasend("Subject: $subject\n");
	$smtp->datasend($message);
	$smtp->dataend();                     # Finish sending the mail
	$smtp->quit;                          # Close the SMTP connection

	return 1;
}

