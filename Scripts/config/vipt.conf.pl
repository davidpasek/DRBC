#############################################################
# Get config of DR & BC Solution 
# Parameters:
#   no param
############################################################# 
sub getConfig {
  my %CONFIG = ();

  #DEBUG 0 = no, 1 = level 1, 2 = level 2, ...
  #$CONFIG{debug} = 1;
  $CONFIG{debug} = 0;
  $CONFIG{debug} = 1;
  #$CONFIG{debug} = 10;
  $CONFIG{script_name} = "drbc";
  $CONFIG{debug_output} = 'c:\\drbc\\log\\drbc.log';

  # CONFIG VIRTUAL SERVERs
  #   VRANGER ... 0/1 (false/true) virtual disks replicated by VizionCore VRanger Pro
  #   EMCRM   ... 0/1 (false/true) RDM disks replicated by EMC Replication Manager
  #   RDM     ... list of RDM disks
  #

  $CONFIG{'SERVER'}{'REPLIKATOR'}{'NIC'}{1} = 'MGMT';

  $CONFIG{'SERVER'}{'LL-DB'}{'NIC'}{1} = 'VI_DMS';
  $CONFIG{'SERVER'}{'LL-DB'}{'RDM'}{1}{'NAME'}='Hard Disk 2';
  $CONFIG{'SERVER'}{'LL-DB'}{'RDM'}{1}{'EMC_LUN_ID'}=300;
  $CONFIG{'SERVER'}{'LL-DB'}{'RDM'}{1}{'ESX_LUN_ID'}=2; # vmhba1:0:2
  $CONFIG{'SERVER'}{'LL-DB'}{'RDM'}{1}{'SCSI_BUS_ID'}=1;
  $CONFIG{'SERVER'}{'LL-DB'}{'RDM'}{2}{'NAME'}='Hard Disk 3';
  $CONFIG{'SERVER'}{'LL-DB'}{'RDM'}{2}{'EMC_LUN_ID'}=200;
  $CONFIG{'SERVER'}{'LL-DB'}{'RDM'}{2}{'ESX_LUN_ID'}=3; # vmhba1:0:3
  $CONFIG{'SERVER'}{'LL-DB'}{'RDM'}{2}{'SCSI_BUS_ID'}=2;
  #$CONFIG{'SERVER'}{'LL-DC'}{'TESTS'}{'BEFORE_POWER_ON'} = "";
  $CONFIG{'SERVER'}{'LL-DB'}{'TESTS'}{'AFTER_POWER_ON'}  = "TEST_DB";
  $CONFIG{'SERVER'}{'LL-DB'}{'TEST'}{'TEST_DB'} = 'c:\\drbc\\scripts\\vipt\\tests\\net_test.pl -h ll-db.home.uw.cz -p 1433';

  $CONFIG{'SERVER'}{'LL-ARCHIVE'}{'NIC'}{1} = 'VI_DMS';
  $CONFIG{'SERVER'}{'LL-ARCHIVE'}{'RDM'}{1}{'NAME'}='Hard Disk 2';
  $CONFIG{'SERVER'}{'LL-ARCHIVE'}{'RDM'}{1}{'EMC_LUN_ID'}=100;
  $CONFIG{'SERVER'}{'LL-ARCHIVE'}{'RDM'}{1}{'ESX_LUN_ID'}=4; # vmhba1:0:4
  $CONFIG{'SERVER'}{'LL-ARCHIVE'}{'RDM'}{1}{'SCSI_BUS_ID'}=2;
  $CONFIG{'SERVER'}{'LL-ARCHIVE'}{'TESTS'}{'BEFORE_POWER_ON'} = "";
  $CONFIG{'SERVER'}{'LL-ARCHIVE'}{'TESTS'}{'AFTER_POWER_ON'}  = "TEST_SPAWNER";
  $CONFIG{'SERVER'}{'LL-ARCHIVE'}{'TEST'}{'TEST_SPAWNER'} = 'c:\\drbc\\scripts\\vipt\\tests\\net_test.pl -h ll-archive.home.uw.cz -p 12420';

  $CONFIG{'SERVER'}{'LL-DC'}{'NIC'}{1} = 'VI_PROD';
  #$CONFIG{'SERVER'}{'LL-DC'}{'TESTS'}{'BEFORE_POWER_ON'} = "";
  $CONFIG{'SERVER'}{'LL-DC'}{'TESTS'}{'AFTER_POWER_ON'}  = "TEST_PING TEST_RPC TEST_LDAP";
  $CONFIG{'SERVER'}{'LL-DC'}{'TEST'}{'TEST_PING'} = 'c:\\drbc\\scripts\\vipt\\tests\\icmp_test.pl -h ll-dc.home.uw.cz';
  $CONFIG{'SERVER'}{'LL-DC'}{'TEST'}{'TEST_RPC'} = 'c:\\drbc\\scripts\\vipt\\tests\\net_test.pl -h ll-dc.home.uw.cz -p 445';
  $CONFIG{'SERVER'}{'LL-DC'}{'TEST'}{'TEST_LDAP'} = 'c:\\drbc\\scripts\\vipt\\tests\\net_test.pl -h ll-dc.home.uw.cz -p 389';

  $CONFIG{'SERVER'}{'VC'}{'NIC'}{1} = 'MGMT';

  $CONFIG{'SERVER'}{'ECM_Cache'}{'NIC'}{1} = 'VI_PROD';
  $CONFIG{'SERVER'}{'ECM_Cache'}{'NIC'}{2} = 'VI_DMS';
  $CONFIG{'SERVER'}{'ECM_Cache'}{'NIC'}{3} = 'VI_TEST';
  $CONFIG{'SERVER'}{'ECM_Cache'}{'NIC'}{4} = 'MGMT';

  $CONFIG{'SERVER'}{'LL-APP-INT'}{'NIC'}{1} = 'VI_PROD';

  $CONFIG{'SERVER'}{'LL-APP-EXT'}{'NIC'}{1} = 'VI_PROD';

  $CONFIG{'SERVER'}{'LL-ADM-IND'}{'NIC'}{1} = 'VI_PROD';

  # CONFIG SECTION ESX HOSTs
  $CONFIG{'ESX'}{'CREDENTIALS'}{'USERNAME'} = "root";
  $CONFIG{'ESX'}{'CREDENTIALS'}{'PASSWORD'} = "password";

  $CONFIG{'ESX'}{'HOST'}{'ESX1-PS'}{'HOSTNAME'} = "esx1-ps.home.uw.cz";
  $CONFIG{'ESX'}{'HOST'}{'ESX1-PS'}{'IP'} = "192.168.20.10";
  $CONFIG{'ESX'}{'HOST'}{'ESX1-PS'}{'DATACENTER'} = "Krizkova";

  $CONFIG{'ESX'}{'HOST'}{'ESX2-PS'}{'HOSTNAME'} = "esx2-ps.home.uw.cz";
  $CONFIG{'ESX'}{'HOST'}{'ESX2-PS'}{'IP'} = "192.168.20.11";
  $CONFIG{'ESX'}{'HOST'}{'ESX2-PS'}{'DATACENTER'} = "Krizkova";
  $CONFIG{'ESX'}{'ESX2-PS'}{'DATACENTER'} = "Krizkova";
  
  $CONFIG{'ESX'}{'HOST'}{'ESX3-PS'}{'HOSTNAME'} = "esx3-ps.home.uw.cz";
  $CONFIG{'ESX'}{'HOST'}{'ESX3-PS'}{'IP'} = "192.168.20.12";
  $CONFIG{'ESX'}{'HOST'}{'ESX3-PS'}{'DATACENTER'} = "Krizkova";

  $CONFIG{'ESX'}{'HOST'}{'ESX4-PS'}{'HOSTNAME'} = "esx4-ps.home.uw.cz";
  $CONFIG{'ESX'}{'HOST'}{'ESX4-PS'}{'IP'} = "192.168.20.13";
  $CONFIG{'ESX'}{'HOST'}{'ESX4-PS'}{'DATACENTER'} = "Krizkova";

  $CONFIG{'ESX'}{'HOST'}{'ESX1-BS'}{'HOSTNAME'} = "esx1-bs.home.uw.cz";
  $CONFIG{'ESX'}{'HOST'}{'ESX1-BS'}{'IP'} = "192.168.20.14";
  $CONFIG{'ESX'}{'HOST'}{'ESX1-BS'}{'DATACENTER'} = "Bardosova";

  $CONFIG{'ESX'}{'HOST'}{'ESX2-BS'}{'HOSTNAME'} = "esx2-bs.home.uw.cz";
  $CONFIG{'ESX'}{'HOST'}{'ESX2-BS'}{'IP'} = "192.168.20.15";
  $CONFIG{'ESX'}{'HOST'}{'ESX2-BS'}{'DATACENTER'} = "Bardosova";

  $CONFIG{'ESX'}{'HOST'}{'ESX3-BS'}{'HOSTNAME'} = "esx3-bs.home.uw.cz";
  $CONFIG{'ESX'}{'HOST'}{'ESX3-BS'}{'IP'} = "192.168.20.16";
  $CONFIG{'ESX'}{'HOST'}{'ESX3-BS'}{'DATACENTER'} = "Bardosova";

  $CONFIG{'ESX'}{'HOST'}{'ESX4-BS'}{'HOSTNAME'} = "esx4-bs.home.uw.cz";
  $CONFIG{'ESX'}{'HOST'}{'ESX4-BS'}{'IP'} = "192.168.20.17";
  $CONFIG{'ESX'}{'HOST'}{'ESX4-BS'}{'DATACENTER'} = "Bardosova";
  
  # CONFIG SECTION VC HOST
  $CONFIG{'VC'}{'HOSTNAME'} = "vc.home.uw.cz";
  $CONFIG{'VC'}{'USERNAME'} = "administrator";
  $CONFIG{'VC'}{'PASSWORD'} = "password";

  # CONFIG SECTION DRBC
  $CONFIG{'DRBC'}{'PRIMARY_DATACENTER'} = "Krizkova";
  $CONFIG{'DRBC'}{'BACKUP_DATACENTER'} = "Bardosova";
  $CONFIG{'DRBC'}{'STANDBY_RESOURCE_POOL'} = "Standby";
  $CONFIG{'DRBC'}{'STANDBY_NETWORK'} = "VI_STANDBY";
  $CONFIG{'DRBC'}{'SERVER_STARTUP_ORDER'} = "ECM_Cache LL-DB LL-ARCHIVE LL-ADM-IND LL-APP-INT LL-APP-EXT VC";
  $CONFIG{'DRBC'}{'SERVER_SHUTDOWN_ORDER'} = "VC LL-APP-EXT LL-APP-INT LL-ADM-IND LL-ARCHIVE LL-DB VC ECM_Cache";
  $CONFIG{'DRBC'}{'SERVER_CHECK_IF_EXIST_SNAPSHOT'} = "LL-DC ECM_Cache LL-DB LL-ARCHIVE LL-APP-INT LL-APP-EXT LL-ADM-IND VC"; 
  $CONFIG{'DRBC'}{'ESX_SERVERS'} = "ESX1-PS ESX2-PS ESX3-PS ESX4-PS ESX1-BS ESX2-BS ESX3-BS ESX4-BS";
  $CONFIG{'DRBC'}{'REPLICATOR'} = "Replikator";
  $CONFIG{'DRBC'}{'DC'} = "LL-DC";
  $CONFIG{'DRBC'}{'VC'} = "VC";

  return %CONFIG;
}
# Function End
1;
