#!/bin/ksh

######################################################################
#Auteur: Aurelien MAUFROY                                            #
#Date: 30/08/2021                                                    #
######################################################################

SauvegardeHotFix()
{
        NumeroHotFix=$1
        FichierHotFix=$2
        Fichier="${FichierHotFix##*/}"
        DOSSIER=`dirname $FichierHotFix`
        LongueurDossier=${#DOSSIER}
        Dossier=`echo $DOSSIER | cut -c7-$LongueurDossier`
        DOSSIER2=$SIGACS
        LongueurDossier2=${#DOSSIER2}
        LongueurDossier2=$(($LongueurDossier2+2))
        Dossier2=`echo $DOSSIER | cut -c${LongueurDossier2}-$LongueurDossier`

        echo "Sauvegarde du fichier $FichierHotFix sous $SIGACS/backup/HotFix/$Version/$NumeroHotFix"
        echo "Sauvegarde du fichier $FichierHotFix sous $SIGACS/backup/HotFix/$Version/$NumeroHotFix" >> $LogHotFix

        echo "mkdir -p $SIGACS/backup/HotFix/$Version/$NumeroHotFix/$Dossier2"
        mkdir -p $SIGACS/backup/HotFix/$Version/$NumeroHotFix/$Dossier2
        cp -pf $SIGACS/$Dossier/$Fichier $SIGACS/backup/HotFix/$Version/$NumeroHotFix/$Dossier2  1>> $LogHotFix 2>&1
        echo  >> $LogHotFix
}

InstallationHotFix()
{
        NumeroHotFix=$1
        FichierHotFix=$2
        Fichier="${FichierHotFix##*/}"
        DOSSIER=`dirname $FichierHotFix`
        LongueurDossier=${#DOSSIER}
        Dossier=`echo $DOSSIER | cut -c7-$LongueurDossier`
        DOSSIER2=$SIGACS
        LongueurDossier2=${#DOSSIER2}
        LongueurDossier2=$(($LongueurDossier2+2))
        Dossier2=`echo $DOSSIER | cut -c${LongueurDossier2}-$LongueurDossier`

        echo "Installation du fichier $FichierHotFix"
        echo "Installation du fichier $FichierHotFix" >> $LogHotFix
        cp -f /admin/depot/hotfixes/$VersionDesign/$NumeroHotFix/$Fichier $SIGACS/$Dossier2/
}

Deploiement()
{
	NumeroHotFix=$1
	FichierHotFix1=$2
	FichierHotFix2=$3
	FichierHotFix3=$4

	if [ $# -gt 4 ]
	then
		echo "ERREUR: le script est fait pour installer 3 fichiers maximum par hotfix => il faut modifier le script"
		echo "Fin de l'exécution du script"
		exit 1
	fi

	echo "-------------------------------"
	echo "$(($#-1)) fichiers à installer pour le hotfixe $NumeroHotFix"
	echo
	echo "Sauvegarde $NumeroHotFix" >> $LogHotFix


        case $# in
                2)
			SauvegardeHotFix $NumeroHotFix $FichierHotFix1
                ;;
                3)
			SauvegardeHotFix $NumeroHotFix $FichierHotFix1
			SauvegardeHotFix $NumeroHotFix $FichierHotFix2
                ;;
                4)
			SauvegardeHotFix $NumeroHotFix $FichierHotFix1 
			SauvegardeHotFix $NumeroHotFix $FichierHotFix2
			SauvegardeHotFix $NumeroHotFix $FichierHotFix3
                ;;
        esac
	echo

	case $# in
		2)
			InstallationHotFix $NumeroHotFix $FichierHotFix1
			RC=$?
		;;
		3)
			InstallationHotFix $NumeroHotFix $FichierHotFix1
			RC1=$?
			InstallationHotFix $NumeroHotFix $FichierHotFix2
			RC2=$?
			RC=$(($RC1+$RC2))
		;;
		4)
			InstallationHotFix $NumeroHotFix $FichierHotFix1
			RC1=$?
			InstallationHotFix $NumeroHotFix $FichierHotFix2
			RC2=$?
			InstallationHotFix $NumeroHotFix $FichierHotFix3
			RC3=$?
			RC=$(($RC1+$RC2+$RC3))
		;;
	esac
	if [ $RC -eq 0 ]
	then
		echo "Installation HF $NumeroHotFix OK"
		echo "Installation HF $NumeroHotFix OK" >> $LogHotFix
	else
		echo "=====>Installation HF $NumeroHotFix KO"
		echo "=====>Installation HF $NumeroHotFix KO" >> $LogHotFix
	fi
	echo 
	echo  >> $LogHotFix
}

VersionDesign=7.40.05002.0000
Version=74050ML2
dat=`date +"%Y-%m-%d-%H%M"`
LogHotFix=$LOG/LogHotFix_${Version}_${dat}.log
fil_mass=/admin/bin/hotfixes/logs/log_$dat-`hostname`-`whoami`.txt
mkdir -p `dirname $fil_mass`

echo "Début de l'installation: `date +"%Y-%m-%d:%H%M%S"`"
echo "Début de l'installation: `date +"%Y-%m-%d:%H%M%S"`" >> $LogHotFix
echo >> $LogHotFix
echo "-------------" >> $LogHotFix
echo "Fichier de log: $LogHotFix"

echo "####################################"
# Controle de la version Design
echo "Controle de la version Design"
if [ -f $SIGACS/openhr/lib/hr-preselection-${VersionDesign}0.jar ]
then
	echo "Version $VersionDesign =========== OK"
	echo "Contrôle de la version $VersionDesign ## `hostname` `whoami` $EnvType $Slice ## =========== OK" >> $LogHotFix
else
	echo "Mauvaise version $VersionDesign"
	echo "Contrôle de lae version $VersionDesign ## $EnvType $Slice ## =========== mauvaise version" >> $LogHotFix
	exit 1
fi
echo "####################################"
echo "-------------" >> $LogHotFix
echo
echo >> $LogHotFix

# Arret du service web
echo "Arret du service web et attente de 120 secondes"
echo "Arret du service web" >> $LogHotFix
if [ -f $SIGACS/tomweb/bin/shutdown.sh ]
then
	cd $SIGACS/tomweb/bin/
	shutdown.sh > /dev/null 2>&1
else
	echo "ERREUR: le fichier \$SIGACS/tomweb/bin/shutdown.sh n'existe pas"
	exit 1
fi

sleep 120
APROCESS=`ps -ef | grep -v "grep"  | grep ${EnvName} | grep tomweb`
if [ "${APROCESS}" != "" ]
then
	pkill -u ${EnvName} -f tomweb
fi


# Déploiement des HotFix
Deploiement 01-224941 $SIGACS/tomweb/webapps/hr-self-service/javascript/hrpro-navigation-darjeeling-ex.js
Deploiement 02-224543 $SIGACS/tomweb/webapps/hr-rich-client/navdos.html $SIGACS/tomweb/webapps/hr-rich-client/navocc.html
Deploiement 03-224038 $SIGACS/tomweb/webapps/hr-rich-client/WEB-INF/classes/com/hraccess/webclient/scheduler/HRMergeJob.class
Deploiement 04-222211 $SIGACS/tomweb/webapps/hr-rich-client/WEB-INF/classes/com/hraccess/webclient/servlets/utils/POIUtil.class $SIGACS/tomweb/webapps/hr-rich-client/WEB-INF/classes/com/hraccess/webclient/scheduler/HRXlsExportJob.class
Deploiement 06-225679 $SIGACS/tomweb/webapps/hr-dms/WEB-INF/view/creationInsertedRecipient_DMS2.jsp
Deploiement 08-226318 $SIGACS/tomweb/webapps/hra-space/WEB-INF/classes/com/hraccess/portal/filter/HRPortalConnectionFilter.class $SIGACS/tomweb/webapps/hra-space/WEB-INF/classes/com/hraccess/portal/filter/"HRPortalConnectionFilter\$1.class"
Deploiement 09-223272 $SIGACS/tomweb/webapps/hr-rich-client/hrcommon.js 
#10-222312 en cours de validation support
#Deploiement 10-222312 $SIGACS/tomweb/webapps/hr-self-service/WEB-INF/tags/footerActions.tag
#11-226517 en cours de validation support
#Deploiement 11-226517 $SIGACS/tomweb/webapps/hr-rich-client/scrollbar.html

# Démarrage du service web
echo "Démarrage du service web"
echo "Démarrage du service web" >> $LogHotFix
startup.sh > /dev/null 2>&1

echo "Fin de l'installation: `date +"%Y-%m-%d:%H%M%S"`"
echo "Fin de l'installation: `date +"%Y-%m-%d:%H%M%S"`" >> $LogHotFix
cat $LogHotFix >> $fil_mass
chmod 777 $fil_mass
