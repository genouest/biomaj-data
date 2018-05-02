#!/usr/bin/perl
#
# Copyright or © or Copr. Allouche D., Assi A., Beausse Y., Caron C., Filangi O., Larre J-M., Leroy H., Martin V.
# mail David.Allouche@toulouse.inra.fr,Hugues.Leroy@irisa.fr,christophe.caron@jouy.inra.fr
#
# BioMaJ Software is a workflows motor engin dedicated to biological bank managenemt.
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
# Author : Genopole Toulouse - Yoann.Beausse@toulouse.inra.fr
#
#-------------------------------------------------------------------------------

=head1 NAME

fastacmdTLSE.pl - Generation de fichiers fasta a partir d'index blast

=head1 SYNOPSIS

fastacmdTLSE.pl [--dbname myBank] [--bank bankName1,[bankName2],...] [--fasta fastaFile1,[fastaFile2],...] 
                [--compress T/F] [--execute system] [--test] [--verbose] [--help]

=head1 Description

Ce script fait partie des PostProcess de BioMaJ.
Permet de generer un fichier fasta a partir des index blast d'une banque.

=over 10

=item * Generation de fichiers fasta a partir des index blast d'une banque via fastacmd

=item * Test la validite du fichier obtenu

=item * Creation d'un lien symbolique 'blast' sur le repertoire flat du repertoire de production de la banque BioMaJ

=item * Creation d'un fichier alias blast dans le repertoire pointe par la variable d'environnement $BLASTDB

=back

=head1 VERSION

Version 0.9
March 2007

=head1 COPYRIGHT

This program is distributed under the CeCILL License. (http://www.cecill.info)

=head1 ARGUMENTS

B<--dbname (-d) myBank>

	BioMaJ bank name 
	default = $ENV{dbname}

B<--bank (-b) 'bankName1[ bankName2[ bankName3]]'>

	Liste des banques blast dont un fichier fasta doit etre genere.
	Si l'option n'est pas renseignee, c'est --dbname qui sera utilise.
	Les noms de banques doivent etre separes par des espaces.
	Ex : --bank 'bank_prot bank_nuc'.
        default = [valeur de --dbname]

B<--fasta (-f) 'fastaFile1[ fastaFile2[ fastaFile3]]'>

	Nom des fichiers fasta pour chaque banque de --bank
	Le premier fichier correspond a la premiere bank ect...
	Si --fasta n'est pas renseigne, le nom du fichier fasta sera le meme que le nom de la banque.
	Si --bank pocede 3 valeurs, --fasta doit comporter 3 noms de fichier ou aucun 
	(dans le cas ou on veut donner le meme nom au fichier fasta qu'aux banques) 
		default = '--bank'

B<--compress (-c) T/F>

	Compression via gzip du fichier fasta.
	defaut = T

B<--execute (-e) system>

	La ligne de commande pour la generation du fichier fasta peut etre executee sur la machine local
	ou etre transcrite dans un fichier pour une execution via un systeme de queue.
	Voir ProcessBiomajLib::executeBatch() pour une utilisation sur votre systeme.
	On doit preciser pour chaque systeme, la commande systeme a utiliser et les options via le fichier unix_command_system.cfg
	Ex pour --execute pbs : 
	 EXECUTE_BATCH_CMD_PBS=/usr/pbs/bin/qsub
	 EXECUTE_BATCH_OPTIONS_PBS=-q longq
	Par defaut, les commandes sont executees via un appel systeme classique (--execute sh)
	default = sh

B<--test (-t)> 

	Execution d'un test pour verifier la coherence du fichier fasta obtenu.
	VERSION 0.9 --> NON OPERATIONNEL

B<--verbose (-v)>

B<--help (-h)>

=head1 AUTHOR

 Yoann Beausse <Yoann.Beausse@toulouse.inra.fr>
 Plateforme Bioinformatique - Genopole Midi-Pyrenees Toulouse

=head1 COMMENTS

=head2 Prerequis

 Ce script fait appel a la librairie Perl 'ProcessBiomajLib.pm'.
 Cette librairie et fastacmdTLSE.pl doivent etre presents dans le repertoire des Process de BioMaJ :
 ($BIOMAJ_ROOT/conf/process/).
 
 Pour les appels aux commandes systeme, le fichier 'unix_command_system.cfg' doit etre renseigne,
 notament pour l'acces aux commandes 'fastacmd' et 'formatdb'.

=head2 Repertoire de sortie

 Tous les fichiers fasta produits sont places dans un repertoire nomme 'fasta' (cf $FASTA_DIR),
 au meme niveau que 'flat', le repertoire des rawdata BioMaJ.
 Un lien symbolique 'blast' (cf $BLAST_DIR) est place sur le repertoire 'flat'.

=head2 Fichier Alias Blast

 Les fichiers alias .pal ou .nal sont places par defaut dans le repertoire de la variable d'environnement 'BLASTDB'.
 Si BLASTDB n'est pas initialisee, par defaut, les alias sont places dans le repertoire 'datadir/blastdb'.
                                                                (datadir une variable defini dans BioMaJ).
 Si necessaire, le repertoire datadir/blastdb est cree a la premier execution.
 Pour Changer le nom du repertoire 'blastdb' modifiez ProcessBioamjLib::$BLASTDB_DIR ou renseignez la variable d'envirennement BLASTDB

=head2 Execution

 Il y a 2 modes d'execution .
 
 1 - mode par defaut, sur la machine locale (--execute sh).
 2 - en batch sur un cluster via une soumission a un systeme de queue. (--execute nomDuSystem) ex : pbs, sge, ...
 L execution reste sequentielle mais delocalisee.
 Pour definir un nouveau systeme, voir ProcessBiomajLib::executeBatch()

=head2 Variables d'Environnement

 BLASTDB
	Repertoire ou les fichiers alias blast seront crees.
	Si BLASTDB n'est pas renseignee, le repertoire par defaut sera 'data.dir'/blastdb 
	(data.dir = propriete de BioMaJ - voir global.properties ou myBank.properties.)

 Verification de l'environnement
    La fonction ProcessBiomajLib::checkBiomajEnvironment() verifie que l'environnement d'execution du Process est correcte pour une interaction avec BioMaJ

=head2 Warning

	Version 0.9 : L'option --test n'est pas active. Il faut revoir la fonction Test()

=head2 Exemples d'utilisation

	La Banque BioMaJ se nomme : "est"
	Exemple avec 3 banques blast dans le repertoire flat (est_human est_mouse est_other) et la banque qui regroupe les 3 autres : 
	est.nal
          est_human.nal       est_mouse.nal       est_otehr.nal
          est_human.00.nhr    est_mouse.00.nhr    est_other.00.nhr
          est_human.00.nin    est_mouse.00.nin    est_other.00.nin
          est_human.01.nhr                        est_other.01.nhr
          est_human.01.nin                        est_other.01.nin
          ...                                     ...

	1) formatdbTLSE.pl
		Par defaut, si --bank n'est pas precise, l'argument recoit le nom de la banque BioMaJ.
		De meme, si --fasta n'est pas precise, il recoit la valeur de --bank
		Ici, il y aura creation d'un fichier fasta est.gz (il y a compression via gzip par defaut) regroupant toutes les sequences de est_human, est_mouse et est_other

	2)  formatdbTLSE.pl --bank 'est_human est_mouse est_other'
	2') formatdbTLSE.pl --bank 'est_human est_mouse est_other' --fasta 'est_human est_mouse est_other'
		Il y aura création de 3 fichiers fasta : est_human.gz est_mouse.gz est_other.gz

	3 ) formatdbTLSE.pl --bank 'est_human est_mouse est_other' --fasta 'toto1 toto2 toto3'
		Il y aura création de 3 fichiers fasta : toto1.gz(pour la banque est_human) toto2.gz(pour la banque est_mouse) toto3.gz(Pour la banque est_other)

	4 ) formatdbTLSE.pl --bank 'est_human est_mouse est_other' --fasta 'toto1 toto2'
		Ici, le programme sort sur erreur ( exit(-1) )
		Il faut le meme nombre d'argument pour --bank et --fasta

=cut


use strict;
use Getopt::Long;
use lib ("$ENV{BIOMAJ_ROOT}/conf/process/.");
use ProcessBiomajLib;

# Execute path var
my %H_CMD;

my $FASTACMD = "fastacmd";

# Arguments du programme
my $DB_NAME = "";
my ($BANK_LIST,$OUTPUT_FILE) = ("","");
my (@A_BANK_LIST,@A_OUTPUT_FILE);
my $COMPRESS = "T";
my $BATCH_SYSTEM = "sh";
my $HELP;
my $VERBOSE;
my $TEST;

# Variables globales au programme
my $PATH_BLAST_DIR;
my $PATH_FASTA_DIR;
my $PATH_FLAT_DIR;
my $PATH_BLASTDB_DIR;

my $FASTA_DIR = "fasta";
my $INDEX_DIR = "blast";

# Traitement des arguments
my $result = GetOptions ("dbname=s" => \$DB_NAME,
                         "bank=s"   => \$BANK_LIST,
                         "fasta=s"  => \$OUTPUT_FILE,
                         "compress=s" => \$COMPRESS, #T/F 
                         "execute=s"  => \$BATCH_SYSTEM,
						 "test"       => \$TEST,
						 "verbose"    => \$VERBOSE,
						 "help"       => \$HELP,
                        );

# MAIN
MAIN:{

	&usage() if ($HELP);	
	&initGlobalVar;
	
	# Creation du repertoire fasta et chdir dedans
	if ( !-e $PATH_FASTA_DIR )
	{
		mkdir "$PATH_FASTA_DIR";
		&Info("mkdir $PATH_FASTA_DIR .");
	} 
	chdir "$PATH_FASTA_DIR";

	# Recup le nombre des sous banques a traiter
	my $cpt = $#A_BANK_LIST;
	
	# Pour chaqu'une de ces sous banques
	for (my $i=0 ; $i<=$cpt ; $i++)
	{
		my $bank = $A_BANK_LIST[$i];
		my $ofile = $A_OUTPUT_FILE[$i];
		
		&computeFastaFile($bank,$ofile);
		&test() if ($TEST);
		
		my $bool_prot_seq  = &getSequenceType($ofile,$COMPRESS);
		&createAliasFile($bank,$bool_prot_seq);
	}
	
	# On place un lien symbolique blast sur le repertoire flat
	&createLinkIndexDir;

}
#############################################################################

=head1 Routines

=head2 function computeFastaFile

	Title        : computeFastaFile
	Usage        : computeFastaFile($bank,$ofile)
	Prerequiiste : none
	Fonction     : Chaine de traitement pour la banque $bank
	Returns      : none
	Args         : $bank : nom de la banque a traiter
	             : $ofile : nom du fichier de sortie fasta
	Globals      : none

=cut
sub computeFastaFile()
{
	my ($bank,$ofile) = (shift,shift);
	
	&clearOutputFiles();
	&outputFile(&createFastaFile($bank,$ofile));
	&printOutputFiles();
	return;
}

=head2 procedure createFastaFile

	Title        : createFastaFile
	Usage        : createFastaFile($bank,$ofile)
	Prerequisite : none
	Fonction     : Constitue la ligne de commande pour fastacmd et l'execute
	Returns      : none
	Args         : $bank : nom de la banque
	             : $ofile : nom du fichier fasta de sortie
	Globals      : $FASTACMD : path pour les commandes system
	             : $PATH_FLAT_DIR : path du repertoire flat de la release
	             : $COMPRESS : boolean. 1 si il faut compresser le fichiei fasta
	             : $BATCH_SYSTEM : systeme pour l'execution des lignes de commandes

=cut
sub createFastaFile
{
	my ($bank,$ofile) = (shift,shift);
	my @a_cmd;
	my $product_file = "$PATH_FASTA_DIR/$ofile";

	push (@a_cmd,"$FASTACMD -D 1 -d $PATH_FLAT_DIR/$bank -o $product_file");

	if ($COMPRESS)
	{
		push (@a_cmd,"$H_CMD{UNIX_RM} -f $product_file.gz") if (-e("$product_file.gz"));
		push (@a_cmd,"$H_CMD{UNIX_GZIP} $product_file");
		$product_file = "$product_file.gz";
	}

	&ProcessBiomajLib::executeBatch(\@a_cmd,$BATCH_SYSTEM,$bank);
	
	if ( !-e($product_file) || -z($product_file) )
	{
		&Error("Output file >$product_file< not exist or null !");
	}

	return $product_file;
}

=head2 procedure createAliasFile

	Title        : createAliasFile
	Usage        : createAliasFile($bank,$bool_prot_seq)
	Prerequisite : none
	Fonction     : Cree le fichier alias pour blast
	Returns      : none
	Args         : $bank : nom de la banque
	             : $bool_prot_seq : 1 pour prot, sinon 0
	Globals      : Variable l'environnement BLASTDB (rien n'est fait si elle n'existe pas)
	             : $BLAST_DIR : "blast"

=cut
sub createAliasFile()
{
	my ($bank,$bool_prot_seq) = (shift,shift);
	
	my $extension  = &getAliasFileExtension($bool_prot_seq);
	my $release = &ProcessBiomajLib::getRemoteRelease();
	
	my $file_alias = "$PATH_BLASTDB_DIR/$bank"."$extension";
	open (ALIAS,">$file_alias");
	print ALIAS <<END
# Alias file
TITLE $bank $release
#
DBLIST $PATH_BLAST_DIR/$bank
	
END
;
	close(ALIAS);
	return;
}

=head2 function getAliasFileExtension

	Title        : getAliasFileExtension
	Usage        : getAliasFileExtension($bool_prot_seq)
	Prerequisite : none
	Fonction     : Selectionne la bonne extension du fichier alias blast (.pal ou .nal)
	Returns      : $extension : ".pal" si prot, sinon ".nal"
	Args         : $bool_prot_seq : 1 pour prot, sinon 0
	Globals      : none

=cut
sub getAliasFileExtension()
{
	my $bool_prot_seq = shift;
	my $extension = ($bool_prot_seq) ? ".pal" : ".nal";
	
	return $extension;
}

=head2 procedure createLinkIndexDir

	Title        : createLinkIndexDir
	Usage        : createLinkIndexDir()
	Prerequisite : none
	Fonction     : Place un lien symbolique blast sur le repertoire flat
	Returns      : none
	Args         : none
	Globals      : $PATH_FLAT_DIR  : path du repertoire flat

=cut
sub createLinkIndexDir
{
	my $cmd = "";
	
	$cmd = "$H_CMD{UNIX_LN} -s $PATH_FLAT_DIR $PATH_BLAST_DIR";
	`$cmd` if ( !-e($PATH_BLAST_DIR) );
	return;
}

=head2 function test

	Title        : test
	Usage        : test()
	Prerequisite : 
	Fonction     : 
	Returns      : $bool : 1 ou 0
	Args         : 
	Globals      : 

=cut
sub test()
{
	return 1;
}

=head2 procedure initGlobalVar

	Title        : initGlobalVar
	Usage        : initGlobalVar()
	Prerequisite : none
	Fonction     : Recupere les valeurs du fichier tmp/bank.var et controle la validite des arguments
	Returns      : none
	Args         : none
	Globals      : 

=cut
sub initGlobalVar()
{	
	&ProcessBiomajLib::checkBiomajEnvironment();
	&ProcessBiomajLib::readCfgFile(\%H_CMD);
	
	### Variable specifique a la banque ###
	$DB_NAME = $ENV{'dbname'} if ( $DB_NAME eq "" );
	
	$PATH_FLAT_DIR      = &ProcessBiomajLib::getPathFuturReleaseFlatDir();
	$PATH_BLAST_DIR     = &ProcessBiomajLib::getPathFuturReleaseMyDir($INDEX_DIR);
	$PATH_FASTA_DIR     = &ProcessBiomajLib::getPathFuturReleaseMyDir($FASTA_DIR);
	
	$PATH_BLASTDB_DIR   = &ProcessBiomajLib::getPathBlastDbDir();
	
	&Error("No such flat directory for $DB_NAME bank.") if ( !-e($PATH_FLAT_DIR) );

	### Variable du programme ###
	&Error("nonvalid option : --compress $COMPRESS") if ( $COMPRESS !~ /(T|F)/ );	
	$COMPRESS    = ( $COMPRESS =~ /T/i ) ? 1 : 0;
	$BANK_LIST   = $DB_NAME   if ($BANK_LIST eq "");
	$OUTPUT_FILE = $BANK_LIST if ($OUTPUT_FILE eq "");
	
	@A_BANK_LIST   = split /\s+/, $BANK_LIST;
	@A_OUTPUT_FILE = split /\s+/, $OUTPUT_FILE;
	
	&usage("No bank of defines") if ( $#A_BANK_LIST == -1 );
	&usage("There is not the same number of bank only of output files\nOption --bank_list and --output_file_list") if ($#A_BANK_LIST != $#A_OUTPUT_FILE);
	
	$FASTACMD = $H_CMD{FASTACMD} if ( defined($H_CMD{FASTACMD}) );

	return;
}

=head2 procedure usage

	Title        : usage
	Usage        : usage($msg)
	Prerequisite : none
	Fonction     : Affiche $msg + l'usage du script + exit(1)
	Returns      : none
	Args         : $msg : message precisant l'erreur
	Globals      : none

=cut
sub usage()
{
	
	my $message = shift;
	
print STDERR "$message\n" if ( defined($message) && $message ne "" );
	
print STDOUT <<END

fastacmdTLSE.pl [--dbname myBank] [--bank bankName1,[bankName2],...] [--fasta fastaFile1,[fastaFile2],...] 
                [--compress T/F] [--execute system] [--test] [--verbose] [--help]

Arguments : 
	
	--dbname     (-d)       : bank name (BioMaJ) [deafault : $ENV{dbname}]
	--bank       (-b)       : bank name (blast)  (without extension)
	--fasta      (-f)       : output fasta file (same order that bank)
	--compress   (-c)       : T/F  [T]      (compress output fasta file)
	--execute    (-e)       : [sh]  (exec mode)
	--test       (-t)       : test le fichier fasta obtenu
	--verbose    (-v)
	--help       (-h)       : ce message

--dbname (-d) myBank

	BioMaJ bank name 
	default = $ENV{dbname}

--bank (-b) 'bankName1[ bankName2[ bankName3]]' 

	Liste des banques blast dont un fichier fasta doit etre genere.
	Si l'option n'est pas renseignee, c'est --dbname qui sera utilise.
	Les noms de banques doivent etre separes par des espaces.
	Ex : --bank 'bank_prot bank_nuc'.
		default = [valeur de --dbname]

--fasta (-f) 'fastaFile1[ fastaFile2[ fastaFile3]]'

	Nom des fichiers fasta pour chaque banque de --bank
	Le premier fichier correspond a la premiere bank ect...
	Si --fasta n'est pas renseigne, le nom du fichier fasta sera le meme que le nom de la banque.
	Si --bank pocede 3 valeurs, --fasta doit comporter 3 noms de fichier ou aucun 
	(dans le cas ou on veut donner le meme nom au fichier fasta qu'aux banques) 
		default = '--bank'
                
--compress (-c) T/F

	Compression via gzip du fichier fasta.
		defaut = T

--execute (-e) system

	La ligne de commande pour la generation du fichier fasta peut etre executee sur la machine local
	ou etre transcrite dans un fichier pour une execution via un systeme de queue.
	Voir ProcessBiomajLib::executeBatch() pour une utilisation sur votre systeme.
	On doit preciser pour chaque systeme, la commande systeme a utiliser et les options via le fichier unix_command_system.cfg
	Ex pour --execute pbs : 
	 EXECUTE_BATCH_CMD_PBS=/usr/pbs/bin/qsub
	 EXECUTE_BATCH_OPTIONS_PBS=-q longq
	Par defaut, les commandes sont executees via un appel systeme classique (--execute sh)
		default = sh

--test (-t)

	Execution d'un test pour verifier la coherence du fichier fasta obtenu.
	VERSION 0.9 --> NON OPERATIONNEL

--verbose (-v)

--help (-h)

END
;
	exit(-1);
}
