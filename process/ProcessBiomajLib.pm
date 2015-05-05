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

=head1 NAME

ProcessBiomajLib.pm - Librairie PERL pour le developpement des Process Biomaj

=head1 Description

Cette librairie propose une suite de fonctions et de variables specifiques au developpement en PERL de Process pour Biomaj.

=head1 VERSION

Version 0.9
March 2007

=head1 COPYRIGHT

This program is distributed under the CeCILL License. (http://www.cecill.info)

=cut

package ProcessBiomajLib;

use strict;
use warnings;
use vars qw(@ISA @EXPORT);
require Exporter;

@ISA = qw(Exporter);

#use vars  qw( $BLAST_DIR $FASTA_DIR $SRS_DIR $FLAT_DIR $LOG_DIR $CURRENT_LINK $FUTUR_RELEASE_LINK);
@EXPORT = qw(clearOutputFiles printOutputFiles outputFile Info Warning Error readCfgFile getSequenceType executeGetz executeCmdSystem);


my $UNIX_COMMAND_SYSTEM_CFG = "$ENV{BIOMAJ_ROOT}/conf/process/unix_command_system.cfg";

my ($OUTPUT_FILES,$OUTPUT_FILES_VOLATILE) = ("","");

my $FLAT_DIR  = "flat";
my $LOG_DIR   = "log";
my $CURRENT_LINK       = "current";
my $FUTUR_RELEASE_LINK = "future_release";

my $BLASTDB_DIR = "blastdb";

=head1 Routines

=head2 Configuration

=head3 procedure checkBiomajEnvironment	exit(-1);

	Title        : checkBiomajEnvironment
	Usage        : checkBiomajEnvironment()
	Prerequisite : none
	Fonction     : Verifie l'existance des variables d'environnement necessaire aux Process.
	Returns      : none
	Args         : none
	Env          : dbname, datadir, dirversion, remoterelease, PP_DEPENDENCE, PP_DEPENDENCE_VOLATILE, PP_WARNING

=cut
sub checkBiomajEnvironment
{
	&Error("the environment variable 'dbname' is not set.")        if ( !exists($ENV{'dbname'}) || $ENV{'dbname'} eq ""); 
	&Error("the environment variable 'datadir' is not set.")       if ( !exists($ENV{'datadir'}) || $ENV{'datadir'} eq "");
	&Error("the environment variable 'dirversion' is not set.")    if ( !exists($ENV{'dirversion'}) || $ENV{'dirversion'} eq "");
	&Error("the environment variable 'remoterelease' is not set.") if ( !exists($ENV{'remoterelease'}) || $ENV{'remoterelease'} eq "");
	&Error("the environment variable 'PP_DEPENDENCE' is not set.") if ( !exists($ENV{'PP_DEPENDENCE'}) || $ENV{PP_DEPENDENCE} eq "");
	&Error("the environment variable 'PP_DEPENDENCE_VOLATILE' is not set.") if ( !exists($ENV{'PP_DEPENDENCE_VOLATILE'}) || $ENV{PP_DEPENDENCE_VOLATILE} eq "");
	&Error("the environment variable 'PP_WARNING' is not set.")    if ( !exists($ENV{'PP_WARNING'}) || $ENV{PP_WARNING} eq "");
	return;
}

=head3 procedure readCfgFile

	Title        : readCfgFile
	Usage        : readCfgFile($rh_cmd)
	Prerequisite : none
	Fonction     : Lit le fichier de conf $UNIX_COMMAND_SYSTEM_CFG.
	             : Place une Cle/Valeur dans $rh_cmd pour chaque ligne CLE=valeur du fichier
	             : Definit des valeur par defaut pour les commandes systeme non definit dans le fichier de conf
	Returns      : none
	Args         : $rh_cmd : reference sur un hash
	Globals      : $UNIX_COMMAND_SYSTEM_CFG

=cut
sub readCfgFile
{
	my ($rh_cmd) = (shift);
	
	my $file = $UNIX_COMMAND_SYSTEM_CFG;
	if ( -e ($file) )
	{
	
		open ( CFG, $file ) or &Warning("Cannot open file config !! >$file<");
		while ( my $line = <CFG> )
		{
			if ( $line !~ /^\s*$/ && $line !~ /^#/ )
			{
				my ($key,$value) = split (/=/, $line, 2);
				chomp($value);
				$rh_cmd->{$key}    = $value;
			}
		}
		close( CFG );
	}
	
	$rh_cmd->{UNIX_CHMOD}  = "chmod"  if ( !defined($rh_cmd->{UNIX_CHMOD}) );
	$rh_cmd->{UNIX_DATE}   = "date"   if ( !defined($rh_cmd->{UNIX_DATE}) );
	$rh_cmd->{UNIX_GUNZIP} = "gunzip" if ( !defined($rh_cmd->{UNIX_GUNZIP}) );
	$rh_cmd->{UNIX_GZIP}   = "gzip"   if ( !defined($rh_cmd->{UNIX_GZIP}) );
	$rh_cmd->{UNIX_HEAD}   = "head"   if ( !defined($rh_cmd->{UNIX_HEAD}) );
	$rh_cmd->{UNIX_LN}     = "ln"     if ( !defined($rh_cmd->{UNIX_LN}) );
	$rh_cmd->{UNIX_MAIL}   = "mail"   if ( !defined($rh_cmd->{UNIX_MAIL}) );
	$rh_cmd->{UNIX_MAKE}   = "make"   if ( !defined($rh_cmd->{UNIX_MAKE}) );
	$rh_cmd->{UNIX_MKDIR}  = "mkdir"  if ( !defined($rh_cmd->{UNIX_MKDIR}) );
	$rh_cmd->{UNIX_MV}     = "mv"     if ( !defined($rh_cmd->{UNIX_MV}) );
	$rh_cmd->{UNIX_PWD}    = "pwd"    if ( !defined($rh_cmd->{UNIX_PWD}) );
	$rh_cmd->{UNIX_RM}     = "rm"     if ( !defined($rh_cmd->{UNIX_RM}) );
	$rh_cmd->{UNIX_SH}     = "sh"     if ( !defined($rh_cmd->{UNIX_SH}) );
	$rh_cmd->{UNIX_TOUCH}  = "touch"  if ( !defined($rh_cmd->{UNIX_TOUCH}) );
	$rh_cmd->{UNIX_ZCAT}   = "zcat"   if ( !defined($rh_cmd->{UNIX_ZCAT}) );
	
	$rh_cmd->{UNIX_GETZ}   = "getz"   if ( !defined($rh_cmd->{UNIX_GETZ}) );
	
	$rh_cmd->{FASTACMD}   = "/usr/local/bioinfo/bin/fastacmd"   if ( !defined($rh_cmd->{FASTACMD}) );
	$rh_cmd->{FORMATDB}   = "/usr/local/bioinfo/bin/formatdb"   if ( !defined($rh_cmd->{FORMATDB}) );
	return;
}

=head2 Communication Process --> Biomaj

=head3 procedure Info

	Title        : Info
	Usage        : Info($msg)
	Prerequisite : none
	Fonction     : Imprime sur STDOUT un message pour info
	Returns      : none
	Args         : $msg
	Globals      : none

=cut
sub Info
{
	my $msg = shift;
	$msg = "" if (!defined($msg));
	print STDOUT "$msg\n";
	return;
}

=head3 procedure Warning

	Title        : Warning
	Usage        : Warning($msg)
	Prerequisite : none
	Fonction     : Imprime sur STDOUT un message warning (Capte par Biomaj par la balise $ENV{PP_WARNING})
	Returns      : none
	Args         : $msg
	Globals      : none

=cut
sub Warning
{
	my $msg = shift;
	$msg = "" if (!defined($msg));
	print STDOUT "$ENV{PP_WARNING}$msg\n";
	return;
}

=head3 procedure Error

	Title        : Error
	Usage        : Error($msg)
	Prerequisite : none
	Fonction     : Imprime sur STDERR un message et quitte le programme avec un code de retour -1
	Returns      : none
	Args         : $msg
	Globals      : none

=cut
sub Error
{
	my $msg = shift;
	$msg = "" if (!defined($msg));
	print STDERR "$msg\n";
	exit(-1);
}

=head3 procedure clearOutputFiles

	Title        : clearOutputFiles
	Usage        : clearOutputFiles($tag)
	Prerequisite : none
	Fonction     : Vide les variables $OUTPUT_FILES et $OUTPUT_FILES_VOLATILE selon $tag
	Returns      : none
	Args         : $tag : ("all", "dependence" ou "volatile")
	             : Selon la valeur utilisee, la (les) liste(s) correspondantes sera(ont) vidée(s)
	             : Defaut : "all"
	Globals      : $OUTPUT_FILES et $OUTPUT_FILES_VOLATILE

=cut
sub clearOutputFiles
{
	my $tag = shift;
	
	$tag = "all" if ( !defined($tag) || $tag eq "" );
	
	&Error("clearOutputFiles($tag) : $tag --> no valid option. [\"\",\"dependence\",\"volatile\",\"all\"]") if ( $tag !~ /(all|volatile|dependence)/ );
	
	if ( $tag eq "all" || $tag eq "volatile" )
	{
		$OUTPUT_FILES_VOLATILE = "";
	}
	
	if ( $tag eq "all" || $tag eq "dependence" )
	{
		$OUTPUT_FILES = "";
	}
	return;
}

=head3 procedure outputFile

	Title        : outputFile
	Usage        : outputFile($file,$tag)
	Prerequisite : none
	Fonction     : Ajout le fichier $file a $OUTPUT_FILES ou $OUTPUT_FILES_VOLATILE (s'il n'est pas deja renseigne)
	Returns      : none
	Args         : $file : fichier produit par le process
	             : $tag  : etiquette du fichier ("dependence" ou "vaolatile")
	             : Defaut : "dependence"
	Globals      : $OUTPUT_FILES et $OUTPUT_FILES_VOLATILE

=cut
sub outputFile
{
	my $file = shift;
	my $tag  = shift;
	
	$tag = "dependence" if ( !defined($tag) || $tag eq "" );
	&Error("outputFile($file,$tag) : $tag --> no valid option. [\"\",\"volatile\",\"dependence\"]") if ( $tag !~ /(volatile|dependence)/ );
	
	if ( $tag eq "volatile" )
	{
		$OUTPUT_FILES_VOLATILE .= "$file " if ( $OUTPUT_FILES_VOLATILE !~ /$file/ );
	}
	else
	{
		$OUTPUT_FILES .= "$file " if ( $OUTPUT_FILES !~ /$file/ );
	}
	
	return;
}

=head3 procedure printOutputFiles

	Title        : printOutputFiles
	Usage        : printOutputFiles()
	Prerequisite : none
	Fonction     : Imprime sur STDOUT les fichiers des listes $OUTPUT_FILES et $OUTPUT_FILES_VOLATILE
	             : avec le tag $ENV{PP_DEPENDENCE} ou $ENV{PP_DEPENDENCE_VOLATILE}
	Returns      : none
	Args         : none
	Globals      : $OUTPUT_FILES et $OUTPUT_FILES_VOLATILE

=cut
sub printOutputFiles
{
	if ( $OUTPUT_FILES ne "" )
	{
		foreach my $ofile (split /\s+/, $OUTPUT_FILES)
 		{
 			print STDOUT "$ENV{PP_DEPENDENCE}$ofile\n";
 		}
	}
	
	if ( $OUTPUT_FILES_VOLATILE ne "" )
	{
		foreach my $ofile (split /\s+/, $OUTPUT_FILES_VOLATILE)
 		{
 			print STDOUT "$ENV{PP_DEPENDENCE_VOLATILE}$ofile\n";
 		}
	}

	return;
}

=head2 Repertoires

=head3 function getFlatDir

	Title        : getFlatDir
	Usage        : getFlatDir()
	Prerequisite : none
	Fonction     : Retourne le nom du repertoire "flat"
	Returns      : String
	Args         : none
	Global       : $LOG_LINK

=cut
sub getFlatDir 
{ 
	return $FLAT_DIR; 
}

=head3 function getLogDir

	Title        : getLogDir
	Usage        : getLogDir()
	Prerequisite : none
	Fonction     : Retourne le nom du repertoire "log"
	Returns      : String
	Args         : none
	Global       : $LOG_LINK

=cut
sub getLogDir
{ 
	return $LOG_DIR;
}

=head3 function getCurrentLink

	Title        : getCurrentLink
	Usage        : getCurrentLink()
	Prerequisite : none
	Fonction     : Retourne le nom du lien "current"
	Returns      : String
	Args         : none
	Global       : $CURRENT_LINK

=cut
sub getCurrentLink
{ 
	return $CURRENT_LINK;
}

=head3 function getFuturReleaseLink

	Title        : getFuturReleaseLink
	Usage        : getFuturReleaseLink()
	Prerequisite : none
	Fonction     : Retourne le nom du lien "future_release"
	Returns      : String
	Args         : none
	Global       : $FUTUR_RELEASE_LINK

=cut
sub getFuturReleaseLink 
{ 
	return $FUTUR_RELEASE_LINK; 
}

=head3 function getRemoteRelease

	Title        : getRemoteRelease
	Usage        : getRemoteRelease()
	Prerequisite : none
	Fonction     : Retourne la release de la banque en cour de mise a jour
	Returns      : String
	Args         : none
	Env          : remoterelease (Biomaj)

=cut
sub getRemoteRelease 
{ 
	return $ENV{'remoterelease'}; 
}

=head3 function getBlastDbDir

	Title        : getBlastDbDir
	Usage        : getBlastDbDir()
	Prerequisite : none
	Fonction     : Retourne le nom du repertoire par defaut pour "blastdb"
	Returns      : String
	Args         : none
	Global       : $BLASTDB_DIR

=cut
sub getBlastDbDir 
{ 
	return $BLASTDB_DIR; 
}

=head3 function getPathBlastDbDir

	Title        : getPathBlastDbDir
	Usage        : getPathBlastDbDir()
	Prerequisite : none
	Fonction     : Retourne le chemin absolu du repertoire pour les alias blast
	             : Retourne ENV{BLASTDB} si elle est renseignee
	             : Retourne ENV{'datadir'}/".&getBlastDbDir() sinon
	Returns      : String
	Args         : none
	Env          : BLASTDB, datadir (placee par Biomaj)

=cut
sub getPathBlastDbDir
{ 
	if ( !exists($ENV{BLASTDB}) || $ENV{BLASTDB} eq "" || !-d($ENV{BLASTDB}) )
	{
		$ENV{BLASTDB} = "$ENV{'datadir'}/".&getBlastDbDir();
		&Warning("the environment variable BLASTDB is not set. Default value is $ENV{BLASTDB}.");
	}
	return $ENV{BLASTDB};
}

=head3 function getPathDirVersion

	Title        : getPathDirVersion
	Usage        : getPathDirVersion()
	Prerequisite : none
	Fonction     : Retourne le chemin absolu du repertoire de production de la banque
	Returns      : String
	Args         : none
	Env          : datadir, dirversion (placee par Biomaj)

=cut
sub getPathDirVersion
{
	my $path_dir_version = "$ENV{'datadir'}/$ENV{'dirversion'}";
	return $path_dir_version;
}

=head3 function getPathFuturReleaseLink

	Title        : getPathFuturReleaseLink
	Usage        : getPathFuturReleaseLink()
	Prerequisite : none
	Fonction     : Retourne le chemin absolu du lien "future_release"
	Returns      : String
	Args         : none
	Globals      : none

=cut
sub getPathFuturReleaseLink
{	
	my $future_release_link = &getPathDirVersion()."/".&getFuturReleaseLink();
	return $future_release_link;
}

=head3 function getPathFuturReleaseDirName

	Title        : getPathFuturReleaseDirName
	Usage        : getPathFuturReleaseDirName()
	Prerequisite : none
	Fonction     : Retourne le chemin absolu du repertoire pointe par le lien "future_release"
	Returns      : String
	Args         : none
	Globals      : none

=cut
sub getPathFuturReleaseDirName
{
	my $future_release_link = &getPathFuturReleaseLink();
	chdir($future_release_link);
	
	my $future_release_dir = `pwd`;
	chomp($future_release_dir);
	return $future_release_dir;
}

=head3 function getPathFuturReleaseFlatDir

	Title        : getPathFuturReleaseFlatDir
	Usage        : getPathFuturReleaseFlatDir()
	Prerequisite : none
	Fonction     : Retourne le chemin absolu du repertoire "flat" de la future release 
	Returns      : String
	Args         : none
	Globals      : none

=cut
sub getPathFuturReleaseFlatDir
{
	my $future_release_flat_dir = &getPathFuturReleaseDirName();
	$future_release_flat_dir .= "/".&getFlatDir();
	return $future_release_flat_dir;
}

=head3 function getPathFuturReleaseLogDir

	Title        : getPathFuturReleaseLogDir
	Usage        : getPathFuturReleaseLogDir()
	Prerequisite : none
	Fonction     : Retourne le chemin absolu du repertoire "log" de la future release 
	Returns      : String
	Args         : none
	Globals      : none

=cut
sub getPathFuturReleaseLogDir
{	
	my $future_release_log_dir = &getPathFuturReleaseDirName();
	$future_release_log_dir .= "/".&getLogDir();
	return $future_release_log_dir;
}

=head3 function getPathFuturReleaseMyDir

	Title        : getPathFuturReleaseMyDir
	Usage        : getPathFuturReleaseMyDir($myDir)
	Prerequisite : none
	Fonction     : Concatene $myDir au chemin absolu du repertoire contenant la release au cours de mise a jour 
	Returns      : String : chemin absolu du repertoire $myDir de la futur release
	Args         : $myDir : Repertoire
	Globals      : none

=cut
sub getPathFuturReleaseMyDir
{	
	my $myDir = shift;
	$myDir = "" if ( !defined($myDir) );
	
	my $future_release_my_dir = &getPathFuturReleaseDirName();
	$future_release_my_dir .= "/$myDir";
	return $future_release_my_dir;
}

=head2 Execution de commande

=head3 function executeCmdSystem

	Title        : executeCmdSystem
	Usage        : executeCmdSystem($cmdLine,$outputfile)
	Prerequisite : none
	Fonction     : Si $outptfile est definit, ajoute ce fichier comme sortie de la ligne de commande ">> $outputfile"
	             : Execute la ligne de commande et verifie que la valeur de retour egale 0. Sinon &Error().
	Returns      : La commande executee.
	Args         : $cmdLine : ligne de commande a executer
	             : $outputfile : fichier de sortie
	Globals      : none

=cut
sub executeCmdSystem
{
	my ($cmdLine,$outputfile) = (shift,shift);
	
	if ( defined($outputfile) && $outputfile ne "" )
	{
		$cmdLine .= " >> $outputfile";
	}
	
	system($cmdLine) == 0 or &Error("system >$cmdLine< a echoue : valeur de retour ".($? >> 8));
	return $cmdLine;
}

=head3 procedure executeBatch

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
	my ($ra_cmdLine,$system,$bank,$option) = (shift,shift,shift,shift);
	$system = "sh" if ( !defined($system) );
	$option = ( !defined($option) ) ? "" :"_".uc($option);
	$bank   = time if ( !defined($bank) );
	
	my %h_cmd;
	&readCfgFile(\%h_cmd);
	
	if ($system ne "" && $system ne "sh")
	{
		$system = uc($system);
		&Error("La commande pour --execute pbs n'est pas définit dans unix_command_system.cfg ( EXECUTE_BATCH_CMD_$system=? )!!\n") if ( !exists($h_cmd{"EXECUTE_BATCH_CMD_$system"}) );
	
		my $execute_cmd = $h_cmd{"EXECUTE_BATCH_CMD_$system"};
		my $execute_option = ( exists($h_cmd{"EXECUTE_BATCH_OPTION_$system$option"}) ) ? $h_cmd{"EXECUTE_BATCH_OPTION_$system$option"} : "";
	
		open (RUNBATCH,">run_$bank.sh");
		print RUNBATCH "#!/bin/bash\n";
		foreach my $cmd ( @{$ra_cmdLine} )
		{
			print RUNBATCH "if [ \$? -eq 0 ]\nthen\n\t";
			print RUNBATCH "$cmd\n";
			print RUNBATCH "else\n\texit \$?\nfi\n";
		}
		close (RUNBATCH);

		system ("$h_cmd{UNIX_CHMOD} +x run_$bank.sh");
		
		my $cmd_batch = "$execute_cmd $execute_option run_$bank.sh";
	
		&Info( "Execute : ".&executeCmdSystem($cmd_batch) );

#		system("$h_cmd{UNIX_RM} run_$bank.sh*");
	}
	elsif ($system eq "sh")
	{
		foreach my $cmd ( @{$ra_cmdLine} )
		{
			&Info( "Execute : ".&executeCmdSystem($cmd) );
		}
	}	

	return;
}

=head3 function executeGetz

	Title        : executeGetz
	Usage        : executeGetz($request,$outputfile)
	Prerequisite : SRS est correctement configure sur le system 
	             : Le requete sera effectuee sur les index SRS du repertoire offline de la banque
	Fonction     : Execute une requete ("$request") getz. Le rsultat est dans le fichier $outputfile
	Returns      : La commande executee pour effectuer la requete
	Args         : $request : requete SRS (sans l'appel a la commande getz)
	             : $outputfile : fichier de sortie pour la requete
	Globals      : none

=cut
sub executeGetz
{
	my ($request,$outputfile) = (shift,shift);
	
	&Error("Pas de requete pour la commande getz.") if ( !defined($request) || $request eq "" );
	
	my $cmd = "getz -off $request";
	if ( defined($outputfile) && $outputfile ne "" )
	{
		$cmd .= " > $outputfile";
	}
	
	print STDOUT `$cmd`;
	return $cmd;
}

=head2 Utils

=head3 function getSequenceType

	Title        : getSequenceType
	Usage        : getSequenceType($fastaFile,$bool_compress)
	Prerequisite : none
	Fonction     : Determine le type de sequence du fichier fasta $fastaFile
	Returns      : $bool_prot_seq : 1 pour sequences proteiques
	             :                  0 pour sequences nucleiques
	Args         : $fastaFile : fichier fasta
	             : $bool_compress : 1 si le fichier est compresse sinon 0 ou ""
	Globals      : none

=cut
sub getSequenceType
{
	my ($file,$compress) = (shift,shift);
	$compress = ( !defined($compress) || !$compress ) ? 0 : 1;
	
	my %h_cmd;
	&readCfgFile(\%h_cmd);
	
	my $cmd_head = "";
	
	if ($compress) 
	{
		$file .= ".gz" if ( $file !~ /\.gz$/ );
		$cmd_head = "$h_cmd{UNIX_ZCAT} $file | $h_cmd{UNIX_HEAD} -n 1000;";
	}
	else 
	{
		$cmd_head = "$h_cmd{UNIX_HEAD} -n 1000 $file;";
	}

	my $seq = `$cmd_head`;
	my @seq = split /\n+/, $seq;
	$seq = "";
	foreach my $line (@seq)
	{
		$seq .= $line if ( $line !~ /^>/ );
	}
	
# fatsa type detection : if DEQILFP found in the first 300 line 
# then fasta type = protein else ==> fasta type = nucleic
	my $bool_prot_seq = ($seq =~ /[EQILFP]/gi) ? 1 : 0; 
	return $bool_prot_seq;
}
1;
