#/bin/bash

if [ -z $1 ] ; then
	echo "No slapcat dump file specified to restore. If you wish to restore a database, type:"
	echo "./ldap-server-setup.sh backupfile"
	echo "Do you want to continue anyway? (y/n)"
	read continueAnyway
	
	if [ "$continueAnyway" != "y" ]; then
		exit 1
	fi
	
fi

restorefile=$1



if [ "`whoami`" != "root" ]; then
	echo "Must be root to run this script"
	exit 1
fi

#Config dir exists
if [ ! -d "configs" ]; then
	echo "Main configs dir missing. Can't do anything without it. This contains all the templates to deploy to the system"
	echo "If you have assumed you don't need this, you're wrong. Please put it back"
	exit 1
fi

#Temp dir exists
if [ ! -d "temp" ]; then
	mkdir temp
fi


#temp ldap-server dir exists
if [ -d "temp/ldap-server" ]; then

	echo  "Cleaning up old config files"
	rm -r "temp/ldap-server"
fi

#copy files
cp -r configs/ldap-server temp/ldap-server



ldapDir="/var/lib/ldap"
#ldapDir="/var/lib/ldap-netsoc"

#Check for old files + delete
if [ -d $ldapDir ]; then
	echo "WARNING: THIS IS PERMANENT"
	echo "ldap files already installed, do you wish to remove? (y/n)"
	read removeOld

	if [ "$removeOld" == "y" ];then
		rm -rf /var/lib/ldap/*
	fi
fi

#TODO set default options with debconf

debconf-set-selections < temp/ldap-server/debconf-defaults

apt-get -y install slapd ldap-utils pwgen

#TODO configure tls ldif file to contain the right location
#TODO handle tls certs/keys

#Make sure to add all schemas first here
ldapadd -H ldapi:/// -Y EXTERNAL -f temp/ldap-server/sudo_schema.ldif
#ldapadd -H ldapi:/// -Y EXTERNAL -f temp/ldap-server/tls.ldif
ldapadd -H ldapi:/// -Y EXTERNAL -f temp/ldap-server/disable_anon.ldif
#removes olcrootpw from the olcDatabase entry. Since we define the password in our dn: cn=admin,dc=netsoc,dc=dit,dc=ie entry, we don't need this
ldapmodify -H ldapi:/// -Y EXTERNAL -f temp/ldap-server/removeolcrootpw.ldif 


#Restore old database

if [ -n $restorefile ]; then
	echo "Stopping slapd and restoring file $restorefile"
	/etc/init.d/slapd stop
	rm /var/lib/ldap/*
	su -s /bin/bash -c "slapadd -b 'dc=netsoc,dc=dit,dc=ie' < $restorefile" openldap
	/etc/init.d/slapd start
fi



