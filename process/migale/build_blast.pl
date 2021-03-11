#!/usr/bin/perl

use warnings;
use diagnostics;
use strict;

use Getopt::Long;
Getopt::Long::Configure( 'no_ignorecase' );

use lib ("$ENV{BIOMAJ_ROOT}/conf/process");
use MigaleBiomaj;
use File::Basename;

#use File::Spec;
#use Date::Format;
#use File::Glob;
#use Data::Dumper;

#variables communes aux scripts
my ( $help, $error, $debug );
my ( %h_pattern, %h_job_args );
my ( @t_job_args, @t_task_args );
$h_job_args{biomaj} = 0;

#variables specifiques a ce script

#Constantes
my $VERSION = '0.5';

$h_job_args{seqid_parse} = 'T';
$h_job_args{index_volume} = 2000;
$h_job_args{sequence_type} = 'F';

&MigaleBiomaj::read_config( \%h_job_args, 'blast' );

GetOptions (
#standard qualifiers
	    'p'             =>sub{ $h_job_args{sequence_type} = 'T' },
	    'outinput=s'    =>\$h_job_args{source_pattern},
#standalone qualifiers   	    
	    'indir=s'       =>\$h_job_args{source_dir},
	    'outdir=s'      =>\$h_job_args{index_dir},
#biomaj qualifiers   
	    'biomaj'        =>\$h_job_args{biomaj},
#optional qualifiers	    	    
	    'execute=s'     =>\$h_job_args{batch_system},
	    'inname=s'      =>\$h_job_args{source_name},
	    'outname=s'     =>\$h_job_args{index_name},
#other qualifiers
	    'debug'         =>\$debug,
	    'help|h'        =>\$help,
	    'version'       =>sub{ print "version : $VERSION\n"; exit -1 },
#formatdb qualifiers
	    'v=i'           =>\$h_job_args{index_volume},
	    'o'             =>sub{ $h_job_args{seqid_parse} = 'F' },
	    'l=s'           =>\$h_job_args{index_log},
	    'a'             =>sub{ $h_job_args{asn_format} = 'T' },
	    'b'             =>sub{ $h_job_args{binary_asn_format} = 'T' },
	    'e'             =>sub{ $h_job_args{seqentry} = 'T' },
	    's'             =>sub{ $h_job_args{sparse} = 'T' } ,
	    'V'             =>sub{ $h_job_args{verbose} = 'T' },
	    'L=s'           =>\$h_job_args{index_alias},
	    'F=s'           =>\$h_job_args{gifile},
	    'B=s'           =>\$h_job_args{binary_gifile},
	    'T=s'           =>\$h_job_args{taxid_file},
	    );

#recuperation de la configuration
 INITITATION: {
     &usage() if ($help);
 
     &error('-outinput requiered')  if( &is_null($h_job_args{source_pattern}) );
     &error('-p requiered')         if( &is_null($h_job_args{sequence_type}) );
 }

 ENVIRONMENT:{
#mise en place de l'environnement dans une session BioMaJ
     if( $h_job_args{biomaj} ) {
	 &info('Load : BioMaJ Environment.');
	 &MigaleBiomaj::biomaj_environment( \%h_job_args );
     }

#mise en place de l'environnement dans une session Standalone
     elsif( ( defined $h_job_args{source_dir} ) && ( defined $h_job_args{index_dir} ) ) {
	 &info('Load : StandAlone Environment.');
	 &MigaleBiomaj::standalone_environment( \%h_job_args );
     }

#probleme donc sortie en usage()
     else {
	 &usage();
     }

#mise en place commune aux deux modes d'execution
     &MigaleBiomaj::make_directory($h_job_args{index_dir});
     chdir $h_job_args{index_dir};

     &MigaleBiomaj::drmaa_initiation() if( $h_job_args{batch_system} eq 'drmaa' );
     &MigaleBiomaj::make_directory($h_job_args{log_dir});

#parse la ligne de commande outinput et cree un hash     
     &MigaleBiomaj::string2hash($h_job_args{source_pattern},\%h_pattern);
 }

#positionne les arguments constants lors du job
 ARGUMENTS:{
     @t_job_args = ( '-p', $h_job_args{sequence_type}, '-v', $h_job_args{index_volume}, '-o', $h_job_args{seqid_parse}, '-l', $h_job_args{log_dir}.'formatdb.log' );

     @t_job_args = ( @t_job_args, '-s', $h_job_args{sparse} )            if( defined $h_job_args{sparse} );
     @t_job_args = ( @t_job_args, '-e', $h_job_args{seqentry} )          if( defined $h_job_args{seqentry} );
     @t_job_args = ( @t_job_args, '-b', $h_job_args{binary_asn_format} ) if( defined $h_job_args{binary_asn_format} );
     @t_job_args = ( @t_job_args, '-V', $h_job_args{verbose} )           if( defined $h_job_args{verbose} );
     @t_job_args = ( @t_job_args, '-a', $h_job_args{asn_format} )        if( defined $h_job_args{asn_format} );

     @t_job_args = ( @t_job_args, '-l', $h_job_args{index_log} )    if( (defined $h_job_args{index_log}) && ($h_job_args{index_log} ne '') );
     @t_job_args = ( @t_job_args, '-L', $h_job_args{index_alias} )  if( (defined $h_job_args{index_alias}) && ($h_job_args{index_alias} ne '') );
     @t_job_args = ( @t_job_args, '-F', $h_job_args{gifile} )       if( (defined $h_job_args{gifile}) && ($h_job_args{gifile} ne '') );
     @t_job_args = ( @t_job_args, '-B',$h_job_args{binary_gifile} ) if( (defined $h_job_args{binary_gifile}) && ($h_job_args{binary_gifile} ne '') );
     @t_job_args = ( @t_job_args, '-T',$h_job_args{taxid_file} )    if( (defined $h_job_args{taxid_file}) && ($h_job_args{taxid_file} ne '') );

     $h_job_args{remote_command} =  $h_job_args{binary_path}.'/'. $h_job_args{formatdb};
 }

#Indexation
MAIN: {
     my ( $dbname, $file );
     my ( %h_files );
     my ( @t_jobid_session );

     &MigaleBiomaj::select_file( $h_job_args{source_dir}, \%h_pattern, \%h_files );

     while( ($dbname, $file) = each(%h_files) ) {
	&debug('Variable>%h_pattern : '.$dbname.' = '.$file) if($debug);
	
	chop $file;
	$dbname = basename $dbname;
	@t_task_args = ( @t_job_args, '-t', $dbname, '-n', $dbname, '-i', $file );
	$h_job_args{argv} = \@t_task_args;
	$h_job_args{job_name} = $h_job_args{index_name}.'.'.$dbname;

	push( @t_jobid_session, &MigaleBiomaj::execution_factory(\%h_job_args) );
	&info('');
	$h_job_args{divisions} .= $dbname . ' ';
    }
    &MigaleBiomaj::drmaa_synchronization( \@t_jobid_session ) if( $h_job_args{batch_system} eq 'drmaa' );

    &make_PNal( $h_job_args{sequence_type}, $h_job_args{databank}, $h_job_args{divisions} );

    &MigaleBiomaj::output_file($h_job_args{index_dir}, \%h_pattern, 'dependence', 1 ) if( $h_job_args{biomaj} == 1 );
    &MigaleBiomaj::print_output_files()                                               if( $h_job_args{biomaj} == 1 );
    exit 0;
}

sub make_PNal() {
    my ( $sequence_type, $databank_name, $divisions, $time );
    my ( @t_count );
    
    ( $sequence_type, $databank_name, $divisions ) = (shift,shift,shift);
    $time = localtime( time );
    
    if( $sequence_type eq 'T' ) {
	$sequence_type = 'pal';	
    }
    else {
	$sequence_type = 'nal';
    }
    return 0 if( -e "$databank_name.$sequence_type" );
    @t_count = split ' ', $divisions;
    return 0 if( (scalar @t_count) == 1 );

    open(FILE,">$databank_name.$sequence_type") || die "Impossible d\'ouvrir le fichier $databank_name.$sequence_type";
    print FILE <<"EOF";
\#
\# Alias file created $time
\#
TITLE $databank_name
\#
DBLIST $divisions
\#
\#GILIST
\#
\#OIDLIST
\#

EOF
close(FILE);
}

sub usage() {
      print <<EOF;
build-blast.pl version $VERSION

Standard qualifiers:
  -p          Type of sequence [T|F]
              T = proteic sequence.
	      F = nucleic sequence.
	      default = F
  -outinput   Association between output and input. [dbname=pattern_in]
              <dbname>=<filename>,[<dbnameN=filenameN>]

BioMaJ qualifiers:
 -biomaj      Execution in BioMaJ session. [Boolean] 
              default = 0, standalone

Standalone qualifiers:        
  -outdir     Directory of output files. [Directory Path]
              Requiered in standalone mode
  -indir      Directory of input files. [Directory Path]
              Requiered in standalone mode

Optional qualifiers:
  -execute    Type of execution. [local|drmaa|debug] Optional
              default = in migale_biomaj.cfg
  -inname     Name of the input directory in the databank directory. [string] Optional
              Only in BioMaJ session
              default = source_name in migale_biomaj.cfg
  -outname    Name of the output directory in the databank directory. [string] Optional
              Only in BioMaJ session
              default = index_name in migale_biomaj.cfg

Other qualifiers:
  -help       Display this message. [boolean]
  -debug      Display debug messages. [boolean]
              default = in migale_biomaj.cfg
  -version    Display version of the script. [boolean]

formatdb qualifiers:
  -v      Database volume size in millions of letters [Integer] Optional
          default = 2000
  -o      Parse options Optional
          T - True: Parse SeqId and create indexes.
          F - False: Do not parse SeqId. Do not create indexes.
	  default = T.
  -l      Logfile name: [File Out]  Optional
          default = formatdb.log
  -a      Input file is database in ASN.1 format (otherwise FASTA is expected) [T/F]  Optional
          T - True,
          F - False.
          default = F
  -b      ASN.1 database in binary mode [T/F]  Optional
          T - binary,
          F - text mode.   
          default = F
  -e      Input is a Seq-entry [T/F]  Optional
          default = F
  -s      Create indexes limited only to accessions - sparse [T/F]  Optional
          default = F
  -V      Verbose: check for non-unique string ids in the database [T/F]  Optional
          default = F
  -L      Create an alias file with this name
          'use' the gifile arg (below) if set to calculate db size
          'use' the BLAST db specified with -i (above) [File Out]  Optional
  -F      Gifile (file containing list of gi\'s) [File In]  Optional
  -B      Binary Gifile produced from the Gifile specified above [File Out]  Optional
  -T      Taxid file to set the taxonomy ids in ASN.1 deflines [File In]  Optional
EOF
   
    exit -1;
}

__END__

=head1 NAME

B<build_blast.pl> - Script permettant de lancer des indexations BLAST sur des banques de données soit a l'interieur d'une session BioMaJ soit de maniere independante.

=head1 VERSION

Version 0.5 (December 2007)

=head1 USAGE

=head2 Indexation de la banque NR

=head3 Session BioMaJ

C<build_blast.pl --biomaj --outinput nr=nr.fasta -p T>

Creation d'une banque 'nr' a partir du fichier 'nr.fasta'.

=head3 Session Standalone

C<build_blast.pl --outdir /db/nr/blast/ --indir /db/nr/fasta/ --outinput nr=nr.fasta -p T>

Creation d'une banque 'nr' dans le repertoire '/db/nr/blast/' a partir du fichier 'nr.fasta' dans le repertoire '/db/nr/fasta/'.

=head1 DESCRIPTION

=over

=item - Gestion des differentes options du programme formatdb

=item - Creation des fichier *.nal ou *.pal lors d'indexations multiples

=back

=head1 REQUIRED ARGUMENTS

Standard qualifiers:
  -p          Type of sequence. [T|F]
              T = proteic sequence
              F = nucleic sequence
              default = F
  -outinput   Association between output and input. [dbname=pattern_in]
              <dbname>=<filename>,[<dbnameN=filenameN>]

BioMaJ qualifiers:
 -biomaj      Execution in BioMaJ session. [Boolean] 
              default = 0, standalone

Standalone qualifiers:        
  -outdir     Directory of output files. [Directory Path]
              Requiered in standalone mode
  -indir      Directory of input files. [Directory Path]
              Requiered in standalone mode


=head1 OPTIONS

Optional qualifiers:
  -execute    Type of execution. [local|drmaa|debug] Optional
              defaut = in migale_biomaj.cfg
  -inname     Name of the input directory in the databank directory. [string] Optional
              Only in BioMaJ session
              default = source_name in migale_biomaj.cfg
  -outname    Name of the output directory in the databank directory. [string] Optional
              Only in BioMaJ session
              default = index_name in migale_biomaj.cfg

Other qualifiers:
  -help       Display this message. [boolean]
  -debug      Display debug messages. [boolean]
              default = in migale_biomaj.cfg
  -version    Display version of the script. [boolean]

formatdb qualifiers:
  -v      Database volume size in millions of letters. [Integer] Optional
          default = 2000
  -o      Parse options. Optional
          T - True : Parse SeqId and create indexes
          F - False : Do not parse SeqId. Do not create indexes
	  default = T.
  -l      Logfile name. [File Out]  Optional
          default = formatdb.log
  -a      Input file is database in ASN.1 format (otherwise FASTA is expected). [T/F]  Optional
          T - True
          F - False
          default = F
  -b      ASN.1 database in binary mode. [T/F]  Optional
          T - True : binary
          F - False : text mode
          default = F
  -e      Input is a Seq-entry. [T/F]  Optional
          default = F
  -s      Create indexes limited only to accessions - sparse [T/F]  Optional
          default = F
  -V      Verbose: check for non-unique string ids in the database [T/F]  Optional
          default = F
  -L      Create an alias file with this name
          'use' the gifile arg (below) if set to calculate db size
          'use' the BLAST db specified with -i (above) [File Out]  Optional
  -F      Gifile (file containing list of gi\'s) [File In]  Optional
  -B      Binary Gifile produced from the Gifile specified above [File Out]  Optional
  -T      Taxid file to set the taxonomy ids in ASN.1 deflines [File In]  Optional

=head1 EXIT STATUS

Exit E<gt>0 : erreur lors de l'indexation

=head1 CONFIGURATION

=head2 Fichier de configuration

C<migale_biomaj.cfg> dans le repertoire conf/process/

=head2 Section [blast]

=head3 Obligatoire

index_name : nom du repertoire stockant les index BLAST

source_name : nom du repertoire stockant les fichiers necessaires a l'indexation BLAST

binary_path : chemin absolue du repertoire contenant les binaires

formatdb : nom du programme formatdb

=head3 Optionnel

cluster_option : options du cluster specifique a l'indexation BLAST

batch_system : mode d'execution specifique a l'indexation BLAST

=head1 DEPENDENCIES

=head2 Modules Perl

warnings, diagnostics, strict

Getopt::Long, MigaleBiomaj, File::Basename

=head2 Programmes externes

=over

=item formatdb

=back

=head1 BUGS AND LIMITATIONS

=over

=item - Le module DRMAAc n'a ete teste que sur le scheduler SGE.

=back

=head1 AUTHOR

Ludovic Legrand L<ludovic.legrand@jouy.inra.fr>

=head1 LICENSE AND COPYRIGHT

Copyright 2007 INRA MIG, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 Fonctions internes

=head1 make_PNal

    Title        : make_PNal
    Usage        : make_PNal($sequence_type,$databank_name,$divisions)
    Prerequisite : none
    Fonction     : Creation d'un fichier *.nal ou *.pal
    Returns      : 
       0 : un fichier existe deja ou il n'y en a pas besoin
    Args         : 
       $sequence_type : type de sequence, T pour proteique et F pour nucleique (en rapport avec l\'option -p de formatdb).
       $databank_name : nom de la banque regroupant les index. ex : genbank.nal regroupe les index des divisions genbank.
       $divisions : le nom des index separe par un espace. ex : gb_env gb_gss gb_est
    Env          : none

=cut


