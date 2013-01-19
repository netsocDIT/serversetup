#!/usr/bin/php
<?php
//Version 1.1 - 2013-01-19
if (!function_exists("ldap_connect"))
{
	echoerr("error, ldap functions in php missing.\nRun: apt-get install php5-ldap\n");
	exit(2);
}
/*
	TODO: Test using a different username (after adding access to create/delete options)
		
options ->
	(ldap server)
	(login)
		dn or username
	(password) 
	show groups + services
	add machine
	add service
	remove machine
	remove service
*/

$shortopts = "s:m:h:D:u:p:P:";
/* -s servicename
   -m machine name
   -h ldap server
   -D bind DN
   -u username
*/
$longopts = array('list', 'add-service', 'add-machine','delete-service', 'delete-machine','force');
$options = getopt($shortopts, $longopts);

//Check proper format of service
if (isset($options['s']) and preg_match("/^[a-zA-Z0-9]+$/", $options['s'])!== 1 )
{
	echoerr( "Error, service name '{$options['s']}' must be alphanumeric\n");
	exit(3);
}

//Check proper format of machine
if (isset($options['m']) and (preg_match("/^[a-zA-Z0-9]+$/", $options['m']) != 1 ))
{
	echoerr("Error, machine name '{$options['m']}' must be alphanumeric\n");
	exit(3);
}

//Check only one primary command
$primaryCommandCount = 0;
foreach (array('list','add-service','delete-service','add-machine','delete-machine') as $primaryCommand)
{
	if (isset($options[$primaryCommand]))
	{
		$primaryCommandCount ++;
	}
}

//Print usage if not exactly 1 primary command
if ($primaryCommandCount != 1)
{
echoerr( "Usage: tool.php OPTION [-h hostname] [-p port] [-u username]  [-D binddn] [-P passwordFile] [--force]  
OPTIONS
	--list
		lists tree of machines + services
	--add-service -s servicename -m machinename 
		autocreates machine if doesn't exist
		--force if service already exists, resets password
	--add-machine -m machine 
		not really necessary but just in case you want to. 
		Adding service accounts should create machine accounts when needed
	--delete-service -s servicename -m machinename
	--delete-machine -m machine deletes machine account and all services within

NOTE: -D BindDN    let's you specify the full DN
      -u username  uses the dn in the form of cn=USERNAME,ou=members,ou=users,dc=netsoc,dc=dit,dc=ie
");
exit(3);
}

if (isset($options['D']) and isset($options['u']) )
{
	echoerr("Error - you may either specify a -u username or a -D binddn but not both\n");
	exit(3);
} 


$connectionOptions = array();

//-u username 
if (isset($options['u']))
{
	$connectionOptions['username'] = $options['u'];
}

//-D binddn
if (isset($options['D']))
{
	$connectionOptions['bindDN'] = $options['D'];
}

//-h hostname
if (isset($options['h']))
{
	$connectionOptions['host'] = $options['h'];
}

//-p port
if (isset($options['p']))
{
	$connectionOptions['port'] = $options['p'];
}

//-P password file
if (isset($options['P']))
{
	$passwordFile = $options['P'];
	$passwordFileData = file_get_contents($passwordFile);

	if ($passwordFileData === false)
	{
		echoerr( "Error opening password file '$passwordFile'\n");
		exit();
	}

	$connectionOptions['password'] = trim($passwordFileData);
}



$ldapConnection = connect_and_bind($connectionOptions);
$hostGroups = get_machines_and_services();


if (isset($options['list']))
{
	display_services();
	exit();
}

if (isset($options['add-service']))
{
	if (! (isset($options['s']) and isset($options['m'])))
	{
		echoerr( "Error - service name and machine name must be specified for --add-service!\n");
		exit(3);
	}

	$force = (isset($options['force'])) ? true : false;
	
	$add_service_result =  add_service($options['s'], $options['m'],$force);
	
	if ($add_service_result !== false)
	{
		echo "dn: cn=" . $options['s'] . ",ou=" . $options['m'] . ",ou=machines,dc=netsoc,dc=dit,dc=ie";
		echo "\npassword: $add_service_result\n";
		exit(0);
	}
	
	exit(4);
}

if (isset($options['add-machine']))
{
	if (!isset($options['m']))
	{
		echoerr( "Error - machine name must be specified!\n");
		exit(3);
	}

	$add_machine_result =  add_machine($options['m']);
	
	if ($add_machine_result !== false)
	{
		echo "Machine creation successful!\n";
		echo "dn: ou=" . $options['m'] . ",ou=machines,dc=netsoc,dc=dit,dc=ie\n";
		exit(0);
	}
	
	exit(4);
}

if (isset($options['delete-service']))
{
	if (isset($options['m']) and isset($options['s']))
	{
		$deleteResult = delete_service($options['s'], $options['m']);
		
		if ($deleteResult == true)
		{
			echo "Successfully deleted service {$options['s']} on machine {$options['m']}\n"; 
		}
	}
	else
	{
		echoerr("Error, please specify both machine and service name to delete a service\n");
	}

}


if (isset($options['delete-machine']))
{
	if (!isset($options['m']))
	{
		echoerr( "Error, please specify the machine name to delete with -m machinename\n");
		exit(3);
	}

	
	$delete_machine_result =  delete_machine($options['m']);
	
	if ($delete_machine_result)
	{
		echo "Successfully deleted machine {$options['m']} and all services within";
		exit(0);
	}
	else
	{
		echoerr( "Failed to delete machine ${options['m']}\n");
		exit(4);
	}
}




function delete_machine($machine)
{
	global $ldapConnection;
	global $hostGroups;
	
	if (!isset($hostGroups[$machine]))
	{
		echoerr( "Error, machine $machine doesn't exist!\n");
		exit(4);
	}
	else
	{
		if (count($hostGroups[$machine]) != 0)
		{
				foreach ($hostGroups[$machine] as $service)
				{
					echo "Deleting $service from $machine\n";
					delete_service($service, $machine);
				}
		}
		
		$deleteDN = "ou=$machine,ou=machines,dc=netsoc,dc=dit,dc=ie";
		$deleteResult = ldap_delete($ldapConnection, $deleteDN);
		if ($deleteResult == false)
		{	
			echoerr("Failed to delete $deleteDN\n");
		}

		return $deleteResult;
	}
}


function delete_service($service,$machine)
{
	global $ldapConnection;
	global $hostGroups;

	if (!isset($hostGroups[$machine][$service]))
	{
		echoerr( "Error, service $service under machine $machine doesn't exist!\n");
		exit(4);
	}
	else
	{
		$deleteDN = "cn=$service,ou=$machine,ou=machines,dc=netsoc,dc=dit,dc=ie";
		$deleteResult = ldap_delete($ldapConnection, $deleteDN);
		if ($deleteResult == false)
		{	
			echoerr( "Failed to delete $deleteDN\n");
		}

		return $deleteResult;
	}
}


function get_machines_and_services()
{
	global $ldapConnection;
	$hostGroups = array();
	$results = ldap_list($ldapConnection, "ou=machines,dc=netsoc,dc=dit,dc=ie", "(objectClass=*)");
	$resultEntries = ldap_get_entries($ldapConnection , $results);

	//Add hostnames to array

	foreach ($resultEntries as $resultEntry)
	{
		$hostname= $resultEntry['ou'][0];
		if ($hostname != "")
		{
			$hostGroups[$hostname] = array();
		}
	}

	//Search hostnames and add services for each one
	foreach ($hostGroups as $hostname => $noused)
	{
		$results = ldap_list($ldapConnection,"ou=$hostname,ou=machines,dc=netsoc,dc=dit,dc=ie", "(objectClass=*)");

		$resultEntries = ldap_get_entries($ldapConnection , $results);
		foreach ($resultEntries as $resultEntry)
		{
			$service = $resultEntry['cn'][0];
			if ($service != "")
			{
				$hostGroups[$hostname][$service] = $service;
			}
		}
	}
	return $hostGroups;
}

function display_services()
{
	global $hostGroups;
	if (count($hostGroups) == 0)
	{
		echo "Machine/service list is empty\n";
	}

	foreach ($hostGroups as $hostname => $hostServices)
	{
		echo "$hostname\n";

		foreach ($hostServices as $service)
		{
			echo "|----- $service\n";
		}
	}
}


function add_service($serviceName ,$machine,$force)
{
	global $ldapConnection;
	global $hostGroups;

	if (!isset($hostGroups[$machine]))
	{
		if (add_machine($machine) === false)
		{
			echoerr( "Error - machine account $machine attempted to be created but failed");
			exit(4);
		}
	}
	
	
	$servicePassword = generate_ssha();
	$newService = array();
	$newService['cn'] = $serviceName;
	$newService['userPassword'] = $servicePassword['hash'];
	$newService['objectClass'][0] = 'organizationalRole';
	$newService['objectClass'][1] = 'simpleSecurityObject';

	if (isset($hostGroups[$machine][$serviceName]))
	{
		if ($force == true)
		{
			$addResult = ldap_modify($ldapConnection, "cn=$serviceName,ou=$machine,ou=machines,dc=netsoc,dc=dit,dc=ie", $newService);
		}
		else
		{
			echoerr( "Error - service $serviceName on machine $machine already exists!\n");
			return false;
		}
	}
	else
	{
		$addResult = ldap_add($ldapConnection, "cn=$serviceName,ou=$machine,ou=machines,dc=netsoc,dc=dit,dc=ie", $newService);
	}

	if (!$addResult)
	{
		echoerr( "ERROR - Adding of service $serviceName account for machine: $machine failed!\n");
		return false;
	}

	return $servicePassword['plaintext'];
}



function generate_ssha($passwordLength = 30)
{
	$characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
	$password = '';

	for ($i = 0; $i < $passwordLength; $i++) 
	{
		$password .= $characters[rand(0, strlen($characters) - 1)];
	}

	$salt = substr(sha1(rand()), 0 , 10);-
	$hash = "{SSHA}" . base64_encode(sha1($password . $salt, true) . $salt);
	
	$result = array('hash' => $hash, 'plaintext' => $password);
	return $result;
}

function add_machine($machineName)
{
	global $ldapConnection;
	$newmachine = array();
	$newmachine['ou'] = $machineName;
	$newmachine['objectClass'] = "organizationalunit";

	$addResult = ldap_add($ldapConnection, "ou=$machineName,ou=machines,dc=netsoc,dc=dit,dc=ie", $newmachine);

	if (!$addResult)
	{
		echoerr( "ERROR - Adding of machine account $machineName failed!\n");
		return false;
	}
	
	return true;
}


function connect_and_bind($options = array())
{
	$ldapServer  = isset($options['host']) ? $options['host'] : "ldap.netsoc.dit.ie";
	$ldapPort  = isset($options['port']) ? $options['port'] : "389";

	if (isset($options['bindDN']))
	{
		$ldapBindDN =  $options['bindDN'];
	}
	elseif (isset($options['username']))
	{
		$ldapBindDN = "cn=" . $options['username'] . ",ou=members,ou=users,dc=netsoc,dc=dit,dc=ie";
	}
	else
	{
		$ldapBindDN = 'cn=admin,dc=netsoc,dc=dit,dc=ie';
	}
	
	$ldapPass  = isset($options['password']) ? $options['password'] : get_password($ldapBindDN);

	$ldapConnection = ldap_connect($ldapServer, $ldapPort); 
	ldap_set_option($ldapConnection, LDAP_OPT_PROTOCOL_VERSION, 3);
	ldap_set_option($ldapConnection, LDAP_OPT_NETWORK_TIMEOUT, 1);

	$bindResult = @ldap_bind($ldapConnection, $ldapBindDN, $ldapPass);
	
	if(!$bindResult)
	{
		echoerr( "Error, " . ldap_error($ldapConnection) . ". Server: $ldapServer\n");
		exit(4);
	}

	return $ldapConnection;
}

function get_password($username)
{
	echoerr("Username: $username\n");
	echoerr("Password: ");
	system('stty -echo');
	$password = trim(fgets(STDIN));
	system('stty echo');
	echoerr("\n");
	return $password;
}


function echoerr($message)
{
	$stderr = fopen('php://stderr','a');
	fwrite($stderr,$message);
	fclose($stderr);
}

?>
