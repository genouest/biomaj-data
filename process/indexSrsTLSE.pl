#!/usr/bin/perl

# Copyright or © or Copr. Allouche D., Assi A., Beausse Y., Caron C., Filangi O., Larre J-M., Leroy H., Martin V.
# mail David.Allouche@toulouse.inra.fr,Hugues.Leroy@irisa.fr,christophe.caron@jouy.inra.fr
#
# Biomaj Software is a workflows motor engin dedicated to biological bank managenemt.
#
# This software is governed by the CeCILL license under French law and
# abiding by the rules of distribution of free software.  You can  use,
# modify and/ or redistribute the software under the terms of the CeCILL
# license as circulated by CEA, CNRS and INRIA at the following URL
# "http://www.cecill.info".
#
# As a counterpart to the access to the source code and  rights to copy,
# modify and redistribute granted by the license, users are provided only
# with a limited warranty  and the software's author,  the holder of the
# economic rights,  and the successive licensors  have only  limited
# liability.
#
# In this respect, the user's attention is drawn to the risks associated
# with loading,  using,  modifying and/or developing or reproducing the
# software by the user in light of its specific status of free software,
# that may mean  that it is complicated to manipulate,  and  that  also
# therefore means  that it is reserved for developers  and  experienced
#
# professionals having in-depth computer knowledge. Users are therefore
# encouraged to load and test the software's suitability as regards their
# requirements in conditions enabling the security of their systems and/or
# data to be ensured and,  more generally, to use and operate it in the
# same conditions as regards security.
#
# The fact that you are presently reading this means that you have had
# knowledge of the CeCILL license and that you accept its terms.
#

# Author : Genopole Toulouse - Jean-Marc.Larre@toulouse.inra.fr - Yoann.Beausse@toulouse.inra.fr
# Version : 0.2
# Date : 02/01/2007
#
# Author : Genopole Toulouse - Jean-Marc.Larre@toulouse.inra.fr
# Version :  0.1
# Date : 01/25/2007
#
# Globals
#

=head1 NAME

indexSrsTLSE.pl - Indexation de banque SRS

=head1 SYNOPSIS

indexSrsTLSE.pl [--dbname bankName] [--logdir logDirectory] [--only_check] [--execute execute_system] [--pvm]
                [--cpu_number cpuNumber] [--force] [--help] [--verbose]

=head1 Description

Ce script fait partie des PostProcess de BioMaJ.
Il permet l'indexation de banques via SRS et le calcul des liens entre cette banque et celles deja indexees.

=over 10

=item * Verifie si la banque a besion d'etre indexee

=item * Appel 'srscheck' pour creer un fichier makefile d'indexation

=item * Execute via la commande 'make' le fichier makefile, soit en local, soit via un system de queue pour du calcul distribue

=item * Verifie l'indexation de la banque

=back

=head1 VERSION

Version 0.9
March 2007

=head1 COPYRIGHT

This program is distributed under the CeCILL License. (http://www.cecill.info)

=head1 ARGUMENTS

B<--dbname (-d) bankname>

	SRS bank name 
		default = \$ENV{dbname}

B<--logdir (-l) 'logDirectory'>

		default = Resultat de &ProcessBiomajLib::getPathFuturReleaseLogDir()

B<--only_check (-o)>

	Test seulement si la banque a besoin d'etre indexee.
    	default = off

B<--execute (-e) system>

	La ligne de commande pour le formatage des fichiers fasta peut etre executee sur la machine local
	ou etre transcrite dans un fichier pour une execution via un systeme de queue.
	Voir ProcessBiomajLib::executeBatch() pour une utilisation sur votre systeme.
	On doit preciser pour chaque system, la commande systeme a utiliser et les options via le fichier unix_command_system.cfg
	Ex pour --execute pbs : 
	 EXECUTE_BATCH_CMD_PBS=/usr/pbs/bin/qsub
	 EXECUTE_BATCH_OPTIONS_PBS=-q longq
	Par defaut, les commandes sont executees via un appel systeme classique (--execute sh)
		default = sh

B<--pvm (-p)>

	Utilisation de pvm pour une execution avec pbs.
		default = off

B<--cpu_number (-c)>

	Specify the CPU number or node number
		default:$CPU_OPTION
		
B<--force (f)>

	Force l'indexation
		default:off

B<--verbose (-v)>

B<--help (-h)>

=head1 AUTHOR

 Yoann Beausse <Yoann.Beausse@toulouse.inra.fr>
 Plateforme Bioinformatique - Genopole Midi-Pyrenees Toulouse

=head1 COMMENTS

=head2 Prerequis

 Ce script fait appel a la librairie Perl 'ProcessBiomajLib.pm'.
 Cette librairie et formatdbTLSE.pl doivent etre presents dans le repertoire des Process de BioMaJ :
 ($BIOMAJ_ROOT/conf/process/).
 
 Pour les appels aux commandes systeme, le fichier 'unix_command_system.cfg' doit etre renseigne,
 notament pour l'acces aux commandes 'formatdb' et 'fastacmd'.
 
 Ce script ne comprend pas l'installation de SRS. Il faut que celle-ci soit correctement realisee.
 Il est fait appel aux commande 'srsscheck' pour constituer un fichier makefile pour indexer la banque et a 
 'make' pour executer ce makefile.

=head2 Repertoire de sortie

 Tous les index produits sont places dans un repertoire nomme 'index' (cf $INDEX_DIR),
 au meme niveau que 'flat', le repertoire des rawdata BioMaJ.

=head2 Execution

 Il y a 2 modes d'execution .
 
 1 - mode par defaut, sur la machine locale (--execute sh).
 2 - en batch sur un cluster via une soumission a un systeme de queue. (--execute nomDuSystem) ex : pbs ou sge
 L execution reste sequentielle mais delocalisee.
 Pour definir un nouveau systeme, voir executeBatch()

=head2 Variables d'Environnement

 SRSROOT
	Repertoire ou les fichiers alias blast seront crees.
	Si BLASTDB n'est pas renseignee, le repertoire par defaut sera 'data.dir'/blastdb 
	(data.dir = propriete de BioMaJ - voir global.properties ou myBank.properties.)

 Verification de l'environnement
    La fonction __initEnvSrsForBiomaj() verifie si toutes les repertoires pour l'indexation SRS sont presents (rep : dir offDir indexDir offIndexDir definit dans srsdb.i)
	La fonction ProcessBiomajLib::checkBiomajEnvironment() verifie que l'environnement d'execution du Process est correcte pour une interaction avec BioMaJ.

=head2 Warning

	Version 0.9

=cut

use strict;
#use vars qw/ %opt /;
use Getopt::Long;
use lib ("$ENV{BIOMAJ_ROOT}/conf/process/.");
use ProcessBiomajLib;

############################################################################
#
#
my ($CPU_OPTION,$BATCH_SYSTEM,$FORCE,$ONLY_CHECK,$LOGDIROPTION,$DB_NAME,$VERBOSE,$HELP,$USEPVM) = ("1","sh","","","","","","","");
my $result = GetOptions (
                         "cpu_number=i"   => \$CPU_OPTION,
						 "execute=s"      => \$BATCH_SYSTEM,
						 "pvm"            => \$USEPVM,
						 "force"          => \$FORCE,
						 "only_check"     => \$ONLY_CHECK,
						 "logdir=s"       => \$LOGDIROPTION,
						 "dbname=s"       => \$DB_NAME,
						 "verbose"        => \$VERBOSE,
						 "help"           => \$HELP,
                        );

###### SRS Parameters #####
my $SRSROOT = $ENV{SRSROOT};
my $SRSINDEX = "$SRSROOT/index";
my $SRSOFFINDEX = "$SRSROOT/offindex";

my $PATH_MAKEFILE_DIR="$SRSROOT/pbs/makefile/"; # Path of srscheck makefile generation

my $SRS_OPTIONS="-nomove -links";      # SrsCheck default options
my $SRSCHECK_OPTIONS;

my $LOCK="$ENV{SRSFLAGS}/BiomajSRSLock";       # Flag name to lock only one indexing 
my $CPUNUMBER=4;                               # Specify the number of default CPU used to indexing 
my $SLEEPTIME=5;                               # Time in hours to wait for the lock, if 0 no wait.

##### SRS Commands #####
my $GETZ="$SRSROOT/bin/linux73/getz";     # Getz command
my $SRSCHECK="$SRSROOT/etc/srscheck";     # SrsCheck command

##### PVM Commands #####
my $PVM      = "/work/pvm3/lib/pvm";
my $PVMGMAKE = "/work/pvm3/bin/LINUX64/pvmgmake";

##### Biomaj Variable #####
my $INDEX_DIR = "srs";

##### Global Variable #####
my %H_CMD;
my @A_UNLINK_DIR = ();
my @A_BANKS = ();

my $PATH_SRS_DIR;
my $PATH_LOG_DIR;

my $PATH_MAKEFILE_FILE;
my $PATH_LOG_FILE;
#End paramters definition
#
############################################################################
#Do not modify below
#


MAIN:
{
	&init();

	foreach my $bank (@A_BANKS)
	{
		&clearOutputFiles();
	
		&setLogFile($bank); 
		&setMakefile($bank);
		&computeBank($bank);
		
	}

	&cleanEnvSrsForBiomaj();
}


############################################################################
# Subroutine definition
############################################################################

=head2 procedure computeBank

	Title        : computeBank
	Usage        : computeBank($bank)
	Prerequisite : none
	Fonction     : Chaine de traitement pour l'indexation de la bank
	Returns      : none
	Args         : $bank : Nom de la banque SRS a indexer
	Globals      : none

=cut
sub computeBank {
	
	my $bank = shift;

	if (&isNecessaryIndexing($bank))
	{
		&ProcessBiomajLib::Info("Indexing is necessary for $bank.");
		if (!$ONLY_CHECK)
		{
			&srsdo($bank);
			
			if (&isCorrectIndexing($bank)) 
			{
	   			&ProcessBiomajLib::Info("SRS indexing finished and seems correct.");
				&getOutputFiles($bank);
				&ProcessBiomajLib::printOutputFiles();
	 		} 
			else 
			{
	    		&ProcessBiomajLib::Error("SRS indexing error.");  
	 		}
		}
	}
	else 
	{
		&ProcessBiomajLib::Info("Nothing to do for $bank.");
	}

	return;
}

=head2 procedure isNecessaryIndexing

	Title        : isNecessaryIndexing
	Usage        : isNecessaryIndexing($bank)
	Prerequisite : none
	Fonction     : Test si la banque a besoin d'etre indexee (srscheck -checkonly -l $bank)
	Returns      : 0 si la banque a besoin d'etre indexee
	             : 1 si pas besoin
	Args         : $bank : Nom de la banque SRS
	Globals      : $SRSCHECK, $SRSCHECK_OPTIONS

=cut
sub  isNecessaryIndexing()
{
	my $bank = shift;
	my $returnValue=`$SRSCHECK  -checkonly -l \"$bank\" $SRSCHECK_OPTIONS`;

	if (($returnValue eq "") || ($returnValue =~ /needs to be moved online/))  {
    	if ($returnValue =~ /needs to be moved online/) {     
       		&ProcessBiomajLib::Info("Index files need to be moved to online.") if $VERBOSE;       
    	}
		return 0
  	} else {
    	return 1
  	}
}

=head2 procedure isCorrectIndexing

	Title        : isCorrectIndexing
	Usage        : isCorrectIndexing($bank)
	Prerequisite : none
	Fonction     : Test l'indexation de la banque par une requete getz (getz -off -c $bank)
	Returns      : Le numbre l'enregistrement de la banque indexee.
	             : 0 si erreur
	Args         : $bank : Nom de la banque SRS
	Globals      : $GETZ

=cut
sub isCorrectIndexing()
{
	my $bank = shift;

	my $returnValue=`$GETZ -off -c \"$bank\"`;  
	if ($returnValue=~ /^[0-9]+$/) {
		return $returnValue;
  	} else {
		return 0;
	} 
}

=head2 procedure srsdo

	Title        : srsdo
	Usage        : srsdo($bank)
	Prerequisite : none
	Fonction     : Execute 'srscheck'
	             : Execute 'srsdo'
	Returns      : none
	Args         : $bank : nom de la banque SRS
	Globals      : $PATH_SRS_DIR

=cut
sub srsdo()
{	
	my $bank = shift;
	&lockIndexing();

	&ProcessBiomajLib::Info("Indexing running for $bank.") if $VERBOSE;
	
	my $cmd = "$SRSCHECK -l \"$bank\" -o $PATH_MAKEFILE_FILE $SRSCHECK_OPTIONS 1>$PATH_LOG_FILE";
	&ProcessBiomajLib::executeCmdSystem($cmd);
		
	my @a_cmdFile = ( &getCmdFile($bank) );
	executeBatch(\@a_cmdFile,$BATCH_SYSTEM,$bank,"srs");

	my $ls = `$H_CMD{UNIX_LS} -1 $SRSOFFINDEX/.`;
	system ("$H_CMD{UNIX_MV} $SRSOFFINDEX/* $SRSINDEX/.") if ( $ls ne "" );
	system ("$H_CMD{UNIX_CHMOD} 644 $SRSINDEX/*");

 	&unlock();
	return;
}

=head2 procedure getCmdFile

	Title        : getCmdFile
	Usage        : getCmdFile($bank)
	Prerequisite : none
	Fonction     : Cree un fichier de commande pour l'execution du srsdo (via make)
	Returns      : Chemin absolu du fichier de commande
	Args         : $bank : nom de la banque SRS
	Globals      : $CPUNUMBER, $PATH_MAKEFILE_FILE, $PATH_LOG_FILE, $USEPVM

=cut
sub getCmdFile
{
	my $bank = shift;
	my $cmdFile = "run_srs_$bank.sh";
	
	open (RUNSRS,">$cmdFile") or &ProcessBiomajLib::Error("Cannot create file : $cmdFile");	
	
	if ( $USEPVM )
	{
		print RUNSRS &getCmdForPVM($bank);
	}
	else
	{
		print RUNSRS "cd $ENV{SRSFLAGS}; $H_CMD{UNIX_MAKE} -j $CPUNUMBER -k -f $PATH_MAKEFILE_FILE all 1>>$PATH_LOG_FILE";
	}
	close(RUNSRS);
	
	system ("$H_CMD{UNIX_CHMOD} +x $cmdFile");
	
	my $path = `pwd`;
	chomp($path);
	
	return "$path/$cmdFile";
}

=head2 procedure getCmdForPVM

	Title        : getCmdForPVM
	Usage        : getCmdForPVM()
	Prerequisite : none
	Fonction     : Constitue le fichier de commande pour une execution via pvm
	Returns      : String : Le contunue du fichier
	Args         : none
	Globals      : $BATCH_SYSTEM, $PATH_LOG_DIR,$CPUNUMBER, $PATH_LOG_FILE, $PVM, $PVMGMAKE, $PATH_MAKEFILE_FILE

=cut
sub getCmdForPVM
{
	my $cmd = "";	

	if ( $BATCH_SYSTEM eq "pbs" )
	{

	# 	$cmd .= "#PBS -A SRS\n";
	# 	$cmd .= "#PBS -j oe\n";
	# 	$cmd .= "#PBS -V\n";	 	
	 	$cmd .= "#PBS -e \"localhost:$PATH_LOG_DIR\"\n";
		$cmd .= "#PBS -l select=$CPUNUMBER:ncpus=2\n";
	 	$cmd .= "#PBS -l place=scatter\n";

		$cmd .= "#!/bin/sh -x\n";

		$cmd .= "# Clean /tmp  for PVM\n";
		$cmd .= "/usr/bin/find /tmp/* -type s -exec /bin/rm -vf {} \;\n";

		$cmd .= "date 1>>$PATH_LOG_FILE\n";
		$cmd .= "echo conf | $PVM \$PBS_NODEFILE\n";
		$cmd .= "cd $ENV{SRSFLAGS}; $PVMGMAKE -j $CPUNUMBER -k -f $PATH_MAKEFILE_FILE all 1>>$PATH_LOG_FILE\n";
		$cmd .= "echo halt | $PVM \n";
		$cmd .= "date 1>>$PATH_LOG_FILE\n";
	}
	elsif ( $BATCH_SYSTEM eq "sge" )
	{
		$cmd .= "date 1>>$PATH_LOG_FILE\n";
		$cmd .= "echo conf | $PVM \$PBS_NODEFILE\n";
		$cmd .= "cd $ENV{SRSFLAGS}; $PVMGMAKE -j $CPUNUMBER -k -f $PATH_MAKEFILE_FILE all 1>>$PATH_LOG_FILE\n";
		$cmd .= "date 1>>$PATH_LOG_FILE\n";
	}
	return $cmd;
}

=head2 procedure executeBatch

	Title        : executeBatch
	Usage        : executeBatch($ra_cmdLine,$system,$bank,$option)
	Prerequisite : none
	Fonction     : Execute une suite de commandes systeme via differentes methode (sh ou cluster)
	Returns      : none
	Args         : $ra_cmdLine : Reference sur array contennat les lignes de commande a executer
	             : $system : systeme a utiliser (sh pbs ... ...)
	             : $bank : nom de la banque (pour nommer le fichier a executer si utilisation de cluster. Peut etre vide)
	             : $option : les options a utiliser. Vide pour les options par defaut(voir ci-dessous)
	Globals      : none
	
	Definition des options pour l'utilisation du calcul distribue :
	    L'executable et les options a utiliser pour le calcul distribue sont definis dans le fihier "unix_command_system.cfg".
	    Exemple : 
	        - Executable pour PBS --> il faut definir une variable "EXECUTE_BATCH_CMD_PBS=/path/qsub"
	        - Executable pour SGE --> il faut definir une variable "EXECUTE_BATCH_CMD_SGE=/path/qsub"
	
	        - Options par defaut pour PBS --> il faut definir une variable "EXECUTE_BATCH_OPTION_PBS=options par defaut"
	        - Options par defaut pour SGE --> il faut definir une variable "EXECUTE_BATCH_OPTION_SGE=options par defaut"
	        - Options particulieres pour PBS --> il faut definir une variable "EXECUTE_BATCH_OPTION_PBS_OPTIONNAME=options pour OPTIONNAME"
	        ...

=cut
sub executeBatch
{
	my ($ra_cmd,$system,$bank,$option) = (shift,shift,shift,shift);
	$system = "sh" if ( !defined($system) );
	$option = ( !defined($option) ) ? "" :"_".uc($option);
	$bank   = time if ( !defined($bank) );
	
	if ($system ne "" && $system ne "sh")
	{
		$system = uc($system);
		&ProcessBiomajLib::Error("The command for --execute pbs is not defined in unix_command_system.cfg ( EXECUTE_BATCH_CMD_$system=? )!!\n") if ( !exists($H_CMD{"EXECUTE_BATCH_CMD_$system"}) );
	
		my $execute_cmd = $H_CMD{"EXECUTE_BATCH_CMD_$system"};
		my $execute_option = ( exists($H_CMD{"EXECUTE_BATCH_OPTION_$system$option"}) ) ? $H_CMD{"EXECUTE_BATCH_OPTION_$system$option"} : "";

		foreach my $cmd ( @{$ra_cmd} )
		{
			my $cmd_batch = "$execute_cmd $execute_option $cmd";
			&ProcessBiomajLib::Info( "Execute : ".&executeCmdSystem($cmd_batch,"$PATH_LOG_DIR/execute.cmd.$bank.log") );
		}
	}
	elsif ($system eq "sh")
	{
		foreach my $cmd ( @{$ra_cmd} )
		{
			&ProcessBiomajLib::Info( "Execute : ".&executeCmdSystem($cmd,"$PATH_LOG_DIR/execute.cmd.$bank.log") );
		}
	}	

	return;
}

=head2 procedure lockIndexing

	Title        : lockIndexing
	Usage        : lockIndexing()
	Prerequisite : none
	Fonction     : Test si un 'lock' existe. Si oui, verifie toutes les 5 minutes pendant le nombre d'heure de $SLEEPTIME (5 par defaut)
	             : Sinon place un 'lock'
	Returns      : Si la fonction a pu placer un 'lock'
	             : Fait appel a ProcessBiomajLib::Error si le 'lock' n'a pas pu etre place.
	Args         : none
	Globals      : $SLEEPTIME, $LOCK

=cut
sub lockIndexing()
{
	my ($sleeptime,$step,$wait);

	if (-e $LOCK) {
 	 # A lock already exists
		if ($SLEEPTIME==0) {
    		&ProcessBiomajLib::Error("Lock exists, perhaps an indexing is already running, we cannot index data. Lock file is $LOCK");
  		} else {
    		$sleeptime=$SLEEPTIME*3600; #Convert in seconds
    		$step=300; # 5 minutes  = 300 seconds
    		$wait=0;    
    		while ($wait <= $sleeptime) {
      			sleep($step);
      			$wait=$wait+$step;
      			if (-e $LOCK) {
        			&ProcessBiomajLib::Info("Lock exists, perhaps an indexing is already running, we cannot index data. Lock file is $LOCK") if $VERBOSE;
      			} else {
        			&ProcessBiomajLib::Info("Set lock. Lock file is $LOCK") if $VERBOSE;
					system ("$H_CMD{UNIX_TOUCH} $LOCK");
        			return 0;
      			}
    		}
    		if ($wait >= $sleeptime) {
       			&ProcessBiomajLib::Error("Lock exists, we have waited, but the lock file is never free. Lock file is $LOCK");    
    		}    
  		}
 	} else {
		&ProcessBiomajLib::Info("Set lock. Lock file is $LOCK") if $VERBOSE;
		system ("$H_CMD{UNIX_TOUCH} $LOCK");
		return 0;
	}
}

=head2 procedure unlock

	Title        : unlock
	Usage        : unlock()
	Prerequisite : none
	Fonction     : Retire le 'lock' a la fin de l'indexation
	Returns      : none
	Args         : none
	Globals      : $LOCK

=cut
sub unlock()
{	
	unlink($LOCK);
	&ProcessBiomajLib::Info("Removing lock file. Lock file is $LOCK") if $VERBOSE;
}

=head2 procedure cleanEnvSrsForBiomaj

	Title        : cleanEnvSrsForBiomaj
	Usage        : cleanEnvSrsForBiomaj()
	Prerequisite : none
	Fonction     : Efface les repertoires temporaire qui ont du etre crees pour le bon fonctionnement de l'indexation
	Returns      : none
	Args         : none
	Globals      : @A_UNLINK_DIR

=cut
sub cleanEnvSrsForBiomaj()
{
	foreach my $dir (@A_UNLINK_DIR)
	{
		my $cmd = "$H_CMD{UNIX_RM} -rf $dir";
		`$cmd`;		
	}
}

=head2 procedure init

	Title        : init
	Usage        : init()
	Prerequisite : none
	Fonction     : Initialise l'environnement de travail du script.
	Returns      : none
	Args         : none
	Globals      : $FORCE, $CPU_OPTION, $HELP

=cut
sub init()
{	
	&getUsage() if $HELP; 
	&__initGlobalVar();
   
   	&ProcessBiomajLib::Info("Verbose mode ON.") if $VERBOSE; 
   	&setForce() if $FORCE; 
	&setBank();
   	&setCpu() if $CPU_OPTION;
	
	&__initEnvSrsForBiomaj();
	
	return;
}

sub __initGlobalVar()
{	
	&ProcessBiomajLib::checkBiomajEnvironment();
	&ProcessBiomajLib::readCfgFile(\%H_CMD);
	
	&ProcessBiomajLib::Error("SRSROOT is not defined !!") if ( $SRSROOT eq "" );
	&ProcessBiomajLib::Error("No such or directory \$SRSROOT: $SRSROOT") if ( !-e($SRSROOT) );
	
	$DB_NAME = $ENV{'dbname'} if ( $DB_NAME eq "" );
	&ProcessBiomajLib::Error("dbname is not define. You must define --dbname or environment variable 'dbname'") if ($DB_NAME eq "");
	
	$PATH_LOG_DIR = &ProcessBiomajLib::getPathFuturReleaseLogDir();
	$PATH_SRS_DIR = &ProcessBiomajLib::getPathFuturReleaseMyDir($INDEX_DIR);
	system("$H_CMD{UNIX_MKDIR} $PATH_LOG_DIR") if ( !-e($PATH_LOG_DIR) );
	system("$H_CMD{UNIX_MKDIR} $PATH_SRS_DIR") if ( !-e($PATH_SRS_DIR) );

#	&ProcessBiomajLib::Error ("--batch_system sh and --pvm : incompatible options") if ( $BATCH_SYSTEM eq "sh" & $USEPVM );
	&ProcessBiomajLib::Error ("You must define --batch_system whith pbs|sge|other for used --pvm") if ( $USEPVM & $BATCH_SYSTEM !~ /(sge|pbs|other)/ );
	
	$BATCH_SYSTEM = "sh" if ( $BATCH_SYSTEM eq "" );
	&ProcessBiomajLib::Error ("nonvalid option : --batch_system $BATCH_SYSTEM\nPossible value : sh,sge,pbs,other") if ( $BATCH_SYSTEM !~ /(sh|sge|pbs|other)/ );
	
	$PATH_MAKEFILE_DIR = $ENV{SRS_MAKEFILEDIR} if ( $ENV{SRS_MAKEFILEDIR} ne "");
	$SRS_OPTIONS      = $ENV{SRS_OPTIONS}     if ( $ENV{SRS_OPTIONS}     ne "");
	$SRSCHECK_OPTIONS = $SRS_OPTIONS;
	$CPUNUMBER       = $ENV{SRS_CPUNUMBER}   if ( $ENV{SRS_CPUNUMBER}   ne "");
	$LOCK            = $ENV{SRS_LOCK}        if ( $ENV{SRS_LOCK}        ne "");
}

sub __initEnvSrsForBiomaj()
{
	my $dir_version           = &ProcessBiomajLib::getPathDirVersion();
	my $srs_online_dir        = "$dir_version/".&ProcessBiomajLib::getCurrentLink();
	my $srs_online_data_dir   = "$srs_online_dir/".&ProcessBiomajLib::getFlatDir();
	my $srs_online_index_dir  = "$srs_online_dir/$INDEX_DIR";
	my $srs_offline_dir       = "$dir_version/".&ProcessBiomajLib::getFuturReleaseLink();
	my $srs_offline_data_dir  = "$srs_offline_dir/".&ProcessBiomajLib::getFlatDir();
	my $srs_offline_index_dir = "$srs_offline_dir/$INDEX_DIR";
 	
	if ( !-e("$srs_online_dir") )
	{
		system("$H_CMD{UNIX_MKDIR} $srs_online_dir");
		system("$H_CMD{UNIX_MKDIR} $srs_online_data_dir");
		system("$H_CMD{UNIX_MKDIR} $srs_online_index_dir");
		
		push(@A_UNLINK_DIR,$srs_online_dir);
		push(@A_UNLINK_DIR,$srs_online_data_dir);
		push(@A_UNLINK_DIR,$srs_online_index_dir);
	}
	elsif ( !-e($srs_online_index_dir) )
	{
		system("$H_CMD{UNIX_MKDIR} $srs_online_index_dir");
		push(@A_UNLINK_DIR,$srs_online_index_dir);
	}
	elsif ( !-e($srs_online_data_dir) )
	{
		system("$H_CMD{UNIX_MKDIR} $srs_online_data_dir");
		push(@A_UNLINK_DIR,$srs_online_data_dir);
	}
	
	system("$H_CMD{UNIX_MKDIR} $srs_offline_index_dir") if ( !-e($srs_offline_index_dir) );
	
	&ProcessBiomajLib::Error("No such or directory : $srs_offline_data_dir")  if ( !-e($srs_offline_data_dir) );
	&ProcessBiomajLib::Error("No such or directory : $srs_offline_index_dir") if ( !-e($srs_offline_index_dir) );
	&ProcessBiomajLib::Error("No such or directory : $srs_online_data_dir")   if ( !-e($srs_online_data_dir) );
	&ProcessBiomajLib::Error("No such or directory : $srs_online_index_dir")  if ( !-e($srs_online_index_dir) );
	
	$GETZ     = $H_CMD{GETZ}     if ( defined($H_CMD{GETZ}) );
	$SRSCHECK = $H_CMD{SRSCHECK} if ( defined($H_CMD{SRSCHECK}) );
}

=head2 procedure setBank

	Title        : setBank
	Usage        : setBank()
	Prerequisite : none
	Fonction     : Initialise @A_BANKS avec les valeur de --dbname (split sur virgule ',')
	Returns      : none
	Args         : nome
	Globals      : @A_BANKS

=cut
sub setBank()
{
	if (!$DB_NAME)
	{
		Warning("dbname in -d option not specified.\nDefault SRS bank : $ENV{dbname}");
		$DB_NAME = $ENV{dbname};
	}
	if (!$DB_NAME)
	{
		&ProcessBiomajLib::Error("--dbname and environment variable dbname are not specified !!");
	}
	
	@A_BANKS = split /,/,$DB_NAME;
}

=head2 procedure setLogFile

	Title        : setLogFile
	Usage        : setLogFile($bank)
	Prerequisite : none
	Fonction     : Renseigne $PATH_LOG_FILE avec de chemin absolu du fichier de log
	Returns      : none
	Args         : $bank : nom de la banque SRS
	Globals      : $PATH_LOG_FILE et $PATH_LOG_DIR

=cut
sub setLogFile() 	
{
	my $bank = shift;

	$PATH_LOG_FILE="$PATH_LOG_DIR/$bank.srs.log";
	&ProcessBiomajLib::Info("The file log is $PATH_LOG_FILE for the bank : $bank.") if $VERBOSE;
}

=head2 procedure setMakefile

	Title        : setMakefile
	Usage        : setMakefile($bank)
	Prerequisite : none
	Fonction     : Renseigne $PATH_MAKEFILE_FILE avec de chemin absolu du fichier makefile
	Returns      : none
	Args         : $bank : nom de la banque SRS
	Globals      : $PATH_MAKEFILE_FILE et $PATH_MAKEFILE_DIR

=cut
sub setMakefile($bank)
{
	my $bank = shift;
	$PATH_MAKEFILE_FILE="$PATH_MAKEFILE_DIR/$bank";
}

=head2 procedure setCpu

	Title        : setCpu
	Usage        : setCpu()
	Prerequisite : none
	Fonction     : Renseigne $CPUNUMBER avec la valeur --cpu
	Returns      : none
	Args         : none
	Globals      : $CPUNUMBER et $CPU_OPTION

=cut
sub setCpu() {
	&ProcessBiomajLib::Info("Force CPU number to $CPU_OPTION.") if $VERBOSE; 
	$CPUNUMBER=$CPU_OPTION;
}

=head2 procedure setForce

	Title        : setForce
	Usage        : setForce()
	Prerequisite : none
	Fonction     : Ajoute l'option -force a la ligne d'option de 'srscheck'
	Returns      : none
	Args         : none
	Globals      : $SRSCHECK_OPTIONS

=cut
sub setForce()
{
	&ProcessBiomajLib::Info("Force indexing mode ON.") if $VERBOSE;
	$SRSCHECK_OPTIONS .= " -force ";
}

=head2 procedure getOutputFiles

	Title        : getOutputFiles
	Usage        : getOutputFiles()
	Prerequisite : none
	Fonction     : Extrait du repertoire des index SRS ($PATH_SRS_DIR), la liste des fichiers index 
	               et fait appel a ProcessBiomajLib::outputFile() pour chaque fichier.
	             : Place les droit 644 (rw-r--r--) sur chaque fichier.
	Returns      : none
	Args         : none
	Globals      : $PATH_SRS_DIR

=cut
sub getOutputFiles()
{
	opendir (SRS_DIR,$PATH_SRS_DIR);
	while (my $file = readdir(SRS_DIR))
	{
		next if ( $file =~ /^\.+$/ );
		&ProcessBiomajLib::outputFile("$PATH_SRS_DIR/$file");
	
		chmod(0644,"$PATH_SRS_DIR/$file");
	}
	closedir(SRS_DIR);
}


#
# Message about this program and how to use it
#
sub getUsage()
{
print STDERR "
This program indexing a bank for SRS.

indexSrsTLSE.pl [--dbname bankName] [--logdir logDirectory] [--only_check] [--execute execute_system] [--pvm]
                [--cpu_number cpuNumber] [--force] [--help] [--verbose]

     --dbname     (d) bankname       : SRS bank name  [default:$ENV{dbname}]
     --logdir     (l) directory      : log directory
     --only_check (o)                : Test if an indexing is necessary [default:off]    
     --execute    (e) execute_system : submit indexing on scheduler (sh|pbs|sge|other) [default:$BATCH_SYSTEM]
     --pvm        (p)                : Used pvm [default:off]
     --cpu_number (c) CpuNumber      : specify the CPU number or node number [default:$CPU_OPTION]
     --force      (f)                : force indexing [default:off]
     --help       (h)                : this (help) message
     --verbose    (v)                : verbose output [default:off]
	
--dbname (-d) bankname

	SRS bank name 
		default = \$ENV{dbname}

--logdir (-l) 'logDirectory'

		default = Resultat de &ProcessBiomajLib::getPathFuturReleaseLogDir()

--only_check (-o)

	Test seulement si la banque a besoin d'etre indexee.
    	default = off

--execute (-e) system

	La ligne de commande pour le formatage des fichiers fasta peut etre executee sur la machine local
	ou etre transcrite dans un fichier pour une execution via un systeme de queue.
	Voir ProcessBiomajLib::executeBatch() pour une utilisation sur votre systeme.
	On doit preciser pour chaque system, la commande systeme a utiliser et les options via le fichier unix_command_system.cfg
	Ex pour --execute pbs : 
	 EXECUTE_BATCH_CMD_PBS=/usr/pbs/bin/qsub
	 EXECUTE_BATCH_OPTIONS_PBS=-q longq
	Par defaut, les commandes sont executees via un appel systeme classique (--execute sh)
		default = sh

--pvm (-p)

	Utilisation de pvm pour une execution avec pbs.
		default = off

--cpu_number (-c)

	Specify the CPU number or node number
		default:$CPU_OPTION
		
--force (f)

	Force l'indexation
		default:off

--verbose (-v)

--help (-h)	

"; 
 
exit 1;
}

