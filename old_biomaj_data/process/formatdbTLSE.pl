#!/usr/bin/perl

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

=head1 NAME

formatdbTLSE.pl - Formatage blast des fichiers fasta de BioMaJ

=head1 SYNOPSIS

formatdbTLSE.pl [--dbname myBank] [--fastahome fastadir] [--fasta regex1,[regexp2],...] [--bank bankName1,[bankName2],...]
                [--no_parse_seqid] [--uncompress T/F] [--execute system] [--test] [--verbose] [--help]

=head1 Description

Ce script fait partie des PostProcess de BioMaJ.
Utilise pour l'indexation via formatdb des fichiers fasta.

=over 10

=item * Creation d'index NCBI blast via formatdb a partir de fichier / banque fasta

=item * Test la validite des index (VERSION 0.9 --> NON FONCTIONNELLE)

=item * Creation d'un lien symbolique 'fasta' sur le repertoire flat du repertoire de production de la banque BioMaJ

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

B<--fastahome (-F)>

	nom du repertoire ou se trouve les fichiers fasta. Par defaut cette valeur vaut 'flat'

B<--fasta (-f) 'regexp1[ regexp2[ regexp3]]'>

	Expression reguliere perl pour selectionner les fichiers a formater
	La premiere expression correspond aux fichiers de la premiere bank ect... ...
	Un groupe de regexp peut contenir plusieurs regexp separes par une virgule et 
	chaque groupe d'expresions doivent etre separes par des espaces.
	Ex : --file '*.aa,*.a *.nt'. Tous les fichier *.aa et *.a constituront la bank 'bank_prot' (cf:--bank)
	Si il y a plus d'expressions que de nom de banques, chaque fichier fasta donnera une banque blast du meme nom.
	default = '.*'

B<--bank (-b) 'bankName1[ bankName2[ bankName3]]'>

	Nom des banques a associer aux regexp de fichiers fasta de l'option --file
	Si l'option n'est pas renseignee, chaque fichiers fasta donnera une banque blast du meme nom.
	Les noms de banques doivent etre separes par des espaces.
	Ex : --bank 'bank_prot bank_nuc'.
        default = ""

B<--no_parse_seqid (-n)>

	Do not parse SeqId. Do not create indexes. (formatdb option -o F)
	default = No activated

B<--uncompress (-u) T/F>

	Permet de determiner le comportement du programme si le(s) fichier(s) sont compresser.
	Si True, le fichier fasta est decompresse par gunzip, indexer par formatdb puis recompresse.
	Si False, la commande sera : gunzip -c bank.fasta | formatdb -i stdin
	defaut = F

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

B<--test (-t)> 

	Execution d'un test pour verifier le bon formatage des banques blast.
	VERSION 0.9 --> NON OPERATIONNEL

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

=head2 Repertoire de sortie

 Tous les index produits sont places dans un repertoire nomme 'blast' (cf $INDEX_DIR),
 au meme niveau que 'flat', le repertoire des rawdata BioMaJ.
 Un lien symbolique 'fasta' (cf $FASTA_DIR) est place sur le repertoire 'flat'.

=head2 Fichier Alias Blast

 Les fichiers alias .pal ou .nal sont places par defaut dans le repertoire de la variable d'environnement 'BLASTDB'.
 Si BLASTDB n'est pas initialisee, par defaut, les alias sont places dans le repertoire 'datadir/blastdb'.
                                                                (datadir une variable defini dans BioMaJ).
 Si necessaire, le repertoire datadir/blastdb est cree a la premier execution.
 Pour Changer le nom du repertoire 'blastdb' modifiez ProcessBioamjLib::$BLASTDB_DIR ou renseignez la variable d'envirennement BLASTDB

=head2 Execution

 Il y a 2 modes d'execution .
 
 1 - mode par defaut, sur la machine locale (--execute sh).
 2 - en batch sur un cluster via une soumission a un systeme de queue. (--execute nomDuSystem) ex : pbs ou sge
 L execution reste sequentielle mais delocalisee.
 Pour definir un nouveau systeme, voir ProcessBiomajLib::executeBatch()

=head2 Variables d'Environnement

 BLASTDB
	Repertoire ou les fichiers alias blast seront crees.
	Si BLASTDB n'est pas renseignee, le repertoire par defaut sera 'data.dir'/blastdb 
	(data.dir = propriete de BioMaJ - voir global.properties ou myBank.properties.)

 Verification de l'environnement
    La fonction ProcessBiomajLib::checkBiomajEnvironment() verifie que l'environnement d'execution du Process est correcte pour une interaction avec BioMaJ

=head2 Exemples d'utilisation

 --fasta permet de definir des expressions regulieres PERL pour selectionner les fichiers fasta a indexer.
 --bank permet de donner un nom a la (aux) banque(s) indexee(s)

	Pour --fasta : On peut definir plusieurs expression reguliere (regexp) separees par des virgules ou des espaces.
	Une virgule separe 2 regexp regroupant des fichiers fasta dans une meme banque.
	Un espace separe 2 regexp regroupant des fichiers fasta de banque differentes.

 Exemple avec 3 fichiers fasta de protein a index : file1 file2 file3

=over 24

=item 1 formatdbTLSE.pl (par defaut : '.*')

	Il y aura creation de 3 banques avec 3 fichiers alias (file1.pal, file2.pal et file3.pal)
	Chaque fichier du repertoire 'flat' est considere comme une banques blast a indexer

=item 2 formatdbTLSE.pl --fasta 'file.*'  (Voir 1)

	Il y aura creation de 3 banques avec 3 fichiers alias (file1.pal, file2.pal et file3.pal)

=item 3 formatdbTLSE.pl --fasta 'file.*' --bank 'myBank'

	Il y aura creation d'une seule banque myBank.pal regroupant les index de file1 file2 et file3

=item 4 formatdbTLSE.pl --fasta 'file[1-2] file3'   --bank 'myBank1 myBank2'

=item 4 formatdbTLSE.pl --fasta 'file1,file2 file3'   --bank 'myBank1 myBank2'

	Il y aura creation de 2 banques. myBank1.pal avec les index file1 et file2. myBank2.pal avec les index toto3

=item 5 formatdbTLSE.pl --fasta 'file[1-2] file3'   --bank 'myBank1'

=item 5 formatdbTLSE.pl --fasta 'file1,file2 file3'   --bank 'myBank1'

	Il y aura creation de 2 banques. myBank1.pal avec les index file1 et file2. file3.pal avec les index file3

=item 6 formatdbTLSE.pl --fasta 'file[1-2] file.*'   --bank 'myBank1 myTotalBank'

	Il y aura creation de 2 banques. myBank1.pal avec les index file1 et file2.
	myTotalBank.pal avec les index file1 file2 et file3

=back

=head2 Warning

	Version 0.9 : L'option --test n'est pas active. Il faut revoir la fonction Test()

=cut

use strict;
use Getopt::Long;
use lib ("$ENV{BIOMAJ_ROOT}/conf/process/.");
use ProcessBiomajLib;

my $VERSION = "0.9";

# Execute path var
my %H_CMD;

my ($FORMATDB,$FASTACMD) = ("formatdb","fastacmd");

my @A_BANK = ();
my @A_REGEXP = ();

# Variables globales au programme
my $PATH_BLAST_DIR;
my $PATH_FLAT_DIR;
my $PATH_LOG_DIR;
my $PATH_FASTA_DIR;
my $PATH_BLASTDB_DIR;

my $FASTA_DIR = "fasta";
my $INDEX_DIR = "blast";

my @A_LIST_FILE;
my @A_LIST_DIR;
my %H_ALIAS_FILE;

# Arguments du programme
my $DB_NAME;
my $VERBOSE;
my $UNCOMPRESS = "F";
my $BATCH_SYSTEM = "sh";
my $TEST;
my $HELP;
my $BANK_BLAST = "";
my $INPUT_FILE_REGEXP = ".*";
my $NO_PARSE;
# chemin par default des fasta 
# par default rien n est fait

my $FastaHome="flat";

my $result = GetOptions ("dbname=s"     => \$DB_NAME,
                         "bank=s"       => \$BANK_BLAST,
			 "fasta=s"      => \$INPUT_FILE_REGEXP, # regexp
                         "fastahome=s"    => \$FastaHome,
                         "uncompress=s" => \$UNCOMPRESS, #T/F
                         "verbose"      => \$VERBOSE,
                         "execute=s"    => \$BATCH_SYSTEM,
                         "test"         => \$TEST,
                         "help"         => \$HELP,
                         "no_parse_seqid" => \$NO_PARSE,
                        );

MAIN:
{
	&usage() if ($HELP);	
	&initGlobalVar();

	# Creation du repertoire des index et chdir dedans
	if ( !-e $PATH_BLAST_DIR )
	{
		mkdir "$PATH_BLAST_DIR";
		&Info("Create repertory : $PATH_BLAST_DIR") if ($VERBOSE);
	}
	chdir "$PATH_BLAST_DIR";
	
	if ( !-e $PATH_LOG_DIR )
	{
		mkdir "$PATH_LOG_DIR";
		&Info("Create repertory : $PATH_LOG_DIR") if ($VERBOSE);
	}
	
	my $rh_list_fasta_file = &getFastaFile();
	
	foreach my $fasta_list_nb ( keys %{$rh_list_fasta_file})
	{
		foreach my $fasta_file ( split /,/,$rh_list_fasta_file->{$fasta_list_nb} )
		{
			&Info("File : $fasta_file");
	
			#Pour chaque fichier correspondant a l'expression reguliere
			my $bool_prot_seq  = &checkSequenceType("$PATH_FLAT_DIR/$fasta_file");
			
			my $bank = &computeFastaFile($fasta_file,$bool_prot_seq);
 			if ( $TEST && !&test($bank) )
 			{
 				&Error("Error test de la banque >$bank< !!! ");
 				exit(-1);
 			}
		
			my $bank_name = ( defined($A_BANK[$fasta_list_nb]) ) ? $A_BANK[$fasta_list_nb] : "";
			&buildHashAliasFile($bank,$bool_prot_seq,$bank_name);
		}
	}
	
	&createAliasFile;
	
	# On place un lien symbolique fasta sur le repertoire flat
	# A PASSER SOUS LE CONTROLE D'UNE OPTION
	&createLinkFastaDir;
}
#############################################################################

=head1 Routines

=head3 function getFastaFile

	Title        : getFastaFile
	Usage        : getFastaFile()
	Prerequisite : none
	Fonction     : Liste tous les fichiers des sous repertoire des rawdata (/flat)
	             : Pour chaque fichier, determine s'il correpond a une regexp 
	Returns      : ref sur hash (key=numero de la regexp, value=liste des fichiers correspondant separes par ,)
	Args         : none
	Globals      : @A_LIST_DIR = liste des repertoire des rawdata (/flat)
	             : @A_LIST_FILE = liste de tous les fichiers rawdata
	             : $PATH_FLAT_DIR = Chemin absolu du repertoire flat de la nouvelle release

=cut
sub getFastaFile()
{
	my @a_list_fasta_file = ();
	my %h_list_fasta_file = ();
	
	push (@A_LIST_DIR,$PATH_FLAT_DIR);
	
	while ( $#A_LIST_DIR != -1 )
	{
		&readDir( shift(@A_LIST_DIR) );
	}

	foreach my $file ( @A_LIST_FILE )
	{
		$file =~ s/$PATH_FLAT_DIR//;
		
		$file=~ s/^\/// if ( $file =~ /^\//);
		
		&selectFastaFile(\%h_list_fasta_file,$file);
	}

	return \%h_list_fasta_file;
}

=head3 procedure selectFastaFile

	Title        : selectFastaFile
	Usage        : selectFastaFile($rh_list_file,$file)
	Prerequisite : none
	Fonction     : classe le $file (dans $rh_list_file) selon son appartenance a une regexp de --fasta
	Returns      : none
	Args         : $rh_list_file : ref sur hash contenant la liste des fichiers fasta classe par regexp.
	               les regexp sont numerote de 0 a n selon leur ordre de declaration dans --fasta
	             : $file = fichier a tester
	Globals      : @A_REGEXP = tableau des regexp de --fasta

=cut
sub selectFastaFile
{
	my ($rh_list_file,$file) = (shift,shift);
	
	for( my $i=0 ; $i<=$#A_REGEXP ; $i++)
	{
		my @a_regexp = split /,/, $A_REGEXP[$i];
		foreach my $regexp (@a_regexp)
		{
			if ( $file =~ /^$regexp$/ )
			{
				$rh_list_file->{$i} .= "$file,";
			}
		}
	}	
}

=head3 procedure readDir

	Title        : readDir
	Usage        : readDir($dir)
	Prerequisite : none
	Fonction     : Liste tous les fichiers et repertoire de $dir
	             : Ajoute les fichiers dans @A_LIST_FILE et les repertoires dans @A_LIST_DIR
	Returns      : ref sur array
	Args         : $dir : repertoire a explorer
	Globals      : @A_LIST_FILE et @A_LIST_DIR

=cut
sub readDir()
{
	my $dir = shift;
	my $list_file;
	
	opendir(REP,$dir);
	while ( my $file = readdir(REP) )
	{
		next if ( $file =~ /^\.+$/);
		
		if ( -d("$dir/$file") )
		{
			push(@A_LIST_DIR,"$dir/$file");
		}
		else
		{
			push (@A_LIST_FILE,"$dir/$file");
		}
	}
	close(REP);
	return;
}

=head2 function computeFastaFile

	Title        : computeFastaFile
	Usage        : computeFastaFile($file,$bool_prot_seq)
	Prerequisite : none
	Fonction     : Chaine de traitement pour l'indexation du fichier fasta
	Returns      : $bank : nom de la banque blast
	Args         : $file : nom du fichier a indexer
	             : $bool_prot_seq : boolean. 1 si c'est un fichier de proteines
	Globals      : $PATH_BLAST_DIR : Chemin complet du repertoire des index blast

=cut
sub computeFastaFile()
{
	my ($file,$bool_prot_seq) = (shift,shift);
	
	&clearOutputFiles();
	&Info("Indexed file : $file") if ( $VERBOSE );

	my $bank = &indexFastaFile($file,$bool_prot_seq);

	# On recupere la liste des fichiers index produits pour les transmettres via STDOUT a BioMaJ
	opendir(BLASTDIR,$PATH_BLAST_DIR);
	while ( my $file = readdir(BLASTDIR) )
	{
		&outputFile("$PATH_BLAST_DIR/$file") if ( $file =~ /^$bank.*\.\w\w\w$/ );
	}
	closedir(BLASTDIR);

	&printOutputFiles();
	return $bank;
}


=head2 function checkSequenceType

	Title        : checkSequenceType
	Usage        : checkSequenceType($file)
	Prerequisite : none
	Fonction     : Determine si le fichier fasta $file est prot ou nucleique
	             : en analysant les lettres des sequences sur les 100 premieres lignes
	Returns      : $bool_prot_seq : 1 pour prot, 0 si nucleique
	Args         : $file : chemin complet du fichier a tester
	Globals      : 

=cut
sub checkSequenceType()
{
	my $file = shift;
	
	# Recupere le nom des fichiers (avec .gz, sans .gz, s'il est compresse)
	my ($file_compress,$file_uncompress,$bool_compress) = &getNameCompressFile($file);
	
	my $file = ($bool_compress) ? $file_compress : $file_uncompress;
	
	return &ProcessBiomajLib::getSequenceType($file,$bool_compress);
}

=head2 procedure indexFastaFile

	Title        : indexFastaFile
	Usage        : indexFastaFile($file,$bool_prot_seq)
	Prerequisite : none
	Fonction     : Construit la ligne de commande pour l'indexation et appel &Execute pour l'executer
	Returns      : nom de la banque blast
	Args         : $file : fichier fasta
	             : $bool_prot_seq : 1 pour seq prot sinon 0
	Globals      : $FORMATDB
	             : $PATH_FLAT_DIR : path du repertoire flat de la release
	             : $PATH_BLAST_DIR : path du repertoire blast de la release
	             : $UNCOMPRESS
	             : %H_CMD

=cut
sub indexFastaFile()
{
	my ($file,$bool_prot_seq) = (shift,shift);
	
	# Recupere le nom des fichiers (avec .gz, sans .gz, s'il est compresse)
	my ($file_compress,$file_uncompress,$bool_compress) = &getNameCompressFile($file);
	my ($protein_option,$mask_move_index)  = &getOptionSeq($bool_prot_seq);
	my @a_path = split /\//, $file_uncompress;
	my $outfile = $a_path[$#a_path]; 
	
	my @a_cmd = ();
	
	chdir($PATH_BLAST_DIR);
	my $parse_option = ($NO_PARSE) ? "F" : "T";
    
	push(@a_cmd,"$FORMATDB -o $parse_option -p $protein_option -i $PATH_FLAT_DIR/$file_uncompress -l $PATH_LOG_DIR/$file_uncompress.log");
	push(@a_cmd,"$H_CMD{UNIX_MV} -f $PATH_FLAT_DIR/$file_uncompress$mask_move_index $PATH_BLAST_DIR");
	
	if ($bool_compress)
    {
    	# Soit il est decompresse, indexe puis recompresse
    	if ( $UNCOMPRESS )
   		{
			unshift(@a_cmd,"$H_CMD{UNIX_GUNZIP} -f $PATH_FLAT_DIR/$file_compress");
    		push(@a_cmd,"$H_CMD{UNIX_GZIP} -f $PATH_FLAT_DIR/$file_uncompress");
    	}
    	# Soit decopmpresse et indexe a la vole
    	else
    	{
			@a_cmd = ();
			push(@a_cmd,"$H_CMD{UNIX_GUNZIP} -c $PATH_FLAT_DIR/$file_compress | $FORMATDB -i stdin -n $PATH_BLAST_DIR/$outfile -o $parse_option -p $protein_option -l $PATH_LOG_DIR/$outfile.log");
    	}
    }
	
	&ProcessBiomajLib::executeBatch(\@a_cmd,$BATCH_SYSTEM,$outfile);
	return $outfile;
}

=head2 function getNameCompressFile

	Title        : getNameCompressFile
	Usage        : getNameCompressFile($file)
	Prerequisite : none
	Fonction     : A partir du nom du fichier fasta de la release, determine s'il est gzippe et retourne le nom du fichier zippe, non zippe 
	Returns      : $file_compress : nom du fichier gzippe
	             : $file_uncompress : nom du fichier non zippe
	             : $bool_compress : 1 si le fichier $file est gzippe sinon 0
	Args         : $file : fichier fasta
	Globals      : none

=cut
sub getNameCompressFile()
{
	my $file_compress = shift;
	
	my $file_uncompress = $file_compress;
	my $bool_compress = 0;
    
	if ( $file_compress =~ /\.gz$/ )
   	{
		$file_uncompress =~ s/\.gz//;
		$bool_compress = 1;
    	}
    
    	return ($file_compress,$file_uncompress,$bool_compress);
}

=head2 function getOptionSeq

	Title        : getOptionSeq
	Usage        : getOptionSeq($bool_prot_seq)
	Prerequisite : Determiner si le fichier fasta est prot ou nucleique via GetSequenceType
	Fonction     : Selon $bool_prot_seq, retourne les valeurs pour les options du programme formatdb et le move des index
	Returns      : $protein_option : T ou F (option -p de formatdb)
	             : $mask_move_index : "\.p*" ou "\.n*" (regexp sur les extensions des fichiers index)
	Args         : $bool_prot_seq : 1 pour prot, 0 pour nucleique
	Globals      : none

=cut
sub getOptionSeq()
{
	my $bool_prot_seq = shift;
	my $protein_option = ($bool_prot_seq) ? "T" : "F";
	my $mask_move_index = ($bool_prot_seq) ? "\.p*" : "\.n*";
	
	return($protein_option,$mask_move_index); 
}
=head2 procedure buildHashAliasFile

	Title        : buildHashAliasFile
	Usage        : buildHashAliasFile($bank,$bool_prot_seq)
	Prerequisite : none
	Fonction     : Renseigne le Hash %H_ALIAS_FILE
                 : Si l'option --bank_blast est renseignee, il y aura creation d'un seul fichier alias (bank_blast.pal ou .nal) regroupant tous les fichiers fasta indexe.
                 : Sinon, un fichier alias est cree par fichier fasta indexe.
	Returns      : none
	Args         : $fasta_file : fichier fasta indexe
	             : $bool_prot_seq : 1 pour prot, sinon 0
	Globals      : %H_ALIAS_FILE

=cut
sub buildHashAliasFile()
{
	my ($fasta_file,$bool_prot_seq,$bank_name) = (shift,shift,shift);
	$bank_name = "" if ( !defined($bank_name) );
	
	
	# On recupere le nom du fichier fasta compresse, le nom du fichier decompresse et un bool si le fichier est compresse ou pas
	# Si le fichier n'est pas compresse, $file_compress = $file_uncompress
	my ($file_compress,$file_uncompress,$bool_compress) = &getNameCompressFile($fasta_file);
	my $extension  = &getAliasFileExtension($bool_prot_seq);
	
	# Selon si $BANK_BLAST est renseigne, la banque blast prendra le nom du fichier fasta indexe ou $BANK_BLAST
	my $title_bank = ($bank_name eq "") ? "$file_uncompress" : "$bank_name";
	my $file_alias = ($bank_name eq "") ? "$PATH_BLASTDB_DIR/$file_uncompress"."$extension" : "$PATH_BLASTDB_DIR/$bank_name"."$extension";
	
	$H_ALIAS_FILE{$file_alias}{TITLE}   = "$title_bank ".&ProcessBiomajLib::getRemoteRelease();
	$H_ALIAS_FILE{$file_alias}{DBLIST} .= "$PATH_BLAST_DIR/$file_uncompress ";
	return;
}

=head2 procedure createAliasFile

	Title        : createAliasFile
	Usage        : createAliasFile($bank,$bool_prot_seq)
	Prerequisite : none
	Fonction     : Cree le fichier alias pour blast
	Returns      : none
	Args         : $bank : nom de la banque
	             : $bool_prot_seq : 1 pour prot, sinon 0
	Globals      : 

=cut
sub createAliasFile()
{
	foreach my $file_alias ( keys %H_ALIAS_FILE )
	{

		unlink($file_alias) if ( -e($file_alias) );

		open (ALIAS,">$file_alias") or &Warning("Cannot create file alias >$file_alias<");
print ALIAS <<END
# Alias file
TITLE $H_ALIAS_FILE{$file_alias}{TITLE}
#
DBLIST $H_ALIAS_FILE{$file_alias}{DBLIST}
	
END
;
		close(ALIAS);
	
		&Info("Create alias file : $file_alias") if ($VERBOSE);
	}

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

=head2 procedure createLinkFastaDir

	Title        : createLinkFastaDir
	Usage        : createLinkFastaDir()
	Prerequisite : none
	Fonction     : Place un lien symbolique fasta sur le repertoire flat
	Returns      : none
	Args         : none
	Globals      : $PATH_FASTA_DIR : path du link fasta
	             : $PATH_FLAT_DIR  : path du repertoire flat
	             : $LN : commande system ln

=cut
sub createLinkFastaDir
{
	my $cmd = "";
	
	$cmd = "$H_CMD{UNIX_LN} -s $PATH_FLAT_DIR $PATH_FASTA_DIR";
	`$cmd` if ( !-e($PATH_FASTA_DIR) );
	return;
}

=head2 function test

	Title        : test
	Usage        : test($bank)
	Prerequisite : Indexation de la banque
	Fonction     : Test si l'indexation est fonctionnelle (fastacmd)
	Returns      : $bool : 1 ou 0
	Args         : $bank : la banque a tester
	Globals      : FASTACMD : executable fastacmd

=cut
sub test()
{
	my $bank = shift;

#############################	
# REVOIR LA FONCTION DE TEST
####
	return 1;
#############################
	
	my ($fastabank,$nb_seq,$nb_letter) = ("","","");
		
	my $cmd = "$FASTACMD -d $bank -I";
	open (FASTACMD,"$cmd |");
	while (my $line = <FASTACMD>)
	{
		chomp($line);
		if ( $line =~ /Database:\s*(.+)/)
		{
			$fastabank = $1;
		}
		if ($line =~ /\s+(\S+) sequences; (\S+) total letters/)
		{
			($nb_seq,$nb_letter) = ($1,$2);
		}
		if ($line =~ /ERROR/)
		{
			($fastabank,$nb_seq,$nb_letter) = ("","","");
			last;
		}
	}
	close(FASTACMD);
	
	&Info("Bank --> $fastabank");
	&Info("$nb_seq sequences -- $nb_letter letters");
	
	my $rvl = ( $fastabank eq "") ? 0 : 1;
	return $rvl;
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
	
	### Variable spe a la banque ###
	$DB_NAME = $ENV{'dbname'} if ( $DB_NAME eq "" );
	
# modif david pour permettre le formatage de fichier or du repertoire flat
	if(  $FastaHome eq ("null")) {
	$PATH_FLAT_DIR      = &ProcessBiomajLib::getPathFuturReleaseFlatDir();
	} else {
	chomp($FastaHome);
        $PATH_FLAT_DIR = &ProcessBiomajLib::getPathFuturReleaseMyDir($FastaHome);
	print " fastahome sub dir =".$FastaHome.". ";
	print " absolut path for fasta is =".$PATH_FLAT_DIR;
	
	}

	$PATH_LOG_DIR       = &ProcessBiomajLib::getPathFuturReleaseLogDir();
	$PATH_BLAST_DIR     = &ProcessBiomajLib::getPathFuturReleaseMyDir($INDEX_DIR);
	$PATH_FASTA_DIR     = &ProcessBiomajLib::getPathFuturReleaseMyDir($FASTA_DIR);
	$PATH_BLASTDB_DIR   = &ProcessBiomajLib::getPathBlastDbDir();
	
	&Error("No such flat directory for $DB_NAME $PATH_FLAT_DIR bank.") if ( !-e($PATH_FLAT_DIR) );
	&Warning("option -file : default value [.*]") if ($INPUT_FILE_REGEXP eq ".*");
		
	$FORMATDB = $H_CMD{FORMATDB} if ( defined($H_CMD{FORMATDB}) );
	$FASTACMD = $H_CMD{FASTACMD} if ( defined($H_CMD{FASTACMD}) );
	
	### Variable du programme ###
	&Usage("nonvalid option : --uncompress $UNCOMPRESS") if ( $UNCOMPRESS !~ /(T|F)/ );	
	$UNCOMPRESS = ( $UNCOMPRESS =~ /T/i ) ? 1 : 0;
	
	@A_BANK = split /\s+/, $BANK_BLAST;
	@A_REGEXP = split /\s+/, $INPUT_FILE_REGEXP;
			
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
	
	&Error("$message") if ( defined($message) && $message ne "" );
	
print STDOUT <<END

formatdbTLSE.pl  -  version $VERSION

formatdbTLSE.pl [--dbname myBank] [--fasta regex1,[regexp2],...] [--bank bankName1,[bankName2],...]
                [--no_parse_seqid] [--uncompress T/F] [--execute sh/pbs/sge/other] [--test] [--verbose] [--help]

Arguments : 
        
	--dbname     (-d) : bank name (BioMaJ) [defaut : $ENV{dbname}]
	--fastahome  (-F) :  In fasta base dir ( default value = flat )
	--fasta      (-f) : regexp file [.*]
	--bank       (-b) : bank name (bank blast) [defaut : ""]
	--no_parse_seqid  : Do not parse SeqId. Do not create indexes. (formatdb option -o F)
	--uncompress (-u) : T/F         [F]
	--execute    (-e) : exec mode [default : 'sh']
	--test       (-t) : execute test after indexing (not functional in 0.9)
	--verbose    (-v) : 
	--help       (-h) : This message
        

--dbname (-d) myBank

	BioMaJ bank name 
		default = \$ENV{dbname}
--fastahome  (-F)
	 directory ou se trouve les fichiers fasta à formater

--fasta (-f) 'regexp1[ regexp2[ regexp3]]'

	Expression reguliere perl pour selectionner les fichiers a formater
	La premiere expression correspond aux fichiers de la premiere bank ect... ...
	Un groupe de regexp peut contenir plusieurs regexp separes par une virgule et 
	chaque groupe d'expresions doivent etre separes par des espaces.
	Ex : --file '*.aa,*.a *.nt'. Tous les fichier *.aa et *.a constituront la bank 'bank_prot' (cf:--bank)
	Si il y a plus d'expressions que de nom de banques, chaque fichier fasta donnera une banque blast du meme nom.
		default = '.*'

--bank (-b) 'bankName1[ bankName2[ bankName3]]'

	Nom des banques a associer aux regexp de fichiers fasta de l'option --file
	Si l'option n'est pas renseignee, chaque fichiers fasta donnera une banque blast du meme nom.
	Les noms de banques doivent etre separes par des espaces.
	Ex : --bank 'bank_prot bank_nuc'.
    	default = ""

--no_parse_seqid (-n)

	Do not parse SeqId. Do not create indexes. (formatdb option -o F)
		default = No activated

--uncompress (-u) T/F

	Permet de determiner le comportement du programme si le(s) fichier(s) sont compresser.
	Si True, le fichier fasta est decompresse par gunzip, indexer par formatdb puis recompresse.
	Si False, la commande sera : gunzip -c bank.fasta | formatdb -i stdin
		defaut = F

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

--test (-t)

	Execution d'un test pour verifier le bon formatage des banques blast.
	VERSION 0.9 --> NON OPERATIONNEL

--verbose (-v)

--help (-h)

END
;
        exit(-1);
}
