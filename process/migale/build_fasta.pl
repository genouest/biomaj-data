#!/usr/bin/perl

use warnings;
use diagnostics;
use strict;

use Getopt::Long;
Getopt::Long::Configure( 'no_ignorecase' );

use lib ("$ENV{BIOMAJ_ROOT}/conf/process");
use MigaleBiomaj;
use File::Basename;
use File::Temp qw/ tempfile /;
use File::Spec;
#use Date::Format;
#use File::Glob;
#use Data::Dumper;

#variables communes aux scripts
my ( $help, $error, $debug );
my ( %h_pattern, %h_job_args );
my ( @t_job_args );
$h_job_args{biomaj} = 0;

#variables specifiques a ce script

#Constantes
my $VERSION = '0.5';
$h_job_args{index_format} = 'ncbi';

&MigaleBiomaj::read_config( \%h_job_args, 'fasta' );

GetOptions (
#standard qualifiers
	    'informat=s'        =>\$h_job_args{source_format},
	    'outinput=s'        =>\$h_job_args{source_pattern},
#biomaj qualifiers
	    'biomaj'	        =>\$h_job_args{biomaj},
#standalone qualifiers
	    'outdir=s'          =>\$h_job_args{index_dir},
	    'indir=s'           =>\$h_job_args{source_dir},
#optional qualifiers
	    'execute=s'         =>\$h_job_args{batch_system},
	    'inname=s'          =>\$h_job_args{source_name},
	    'outname=s'         =>\$h_job_args{index_name},
#other qualifiers
	    'debug'             =>\$debug,
	    'help'              =>\$help,
	    'version'           =>sub{ print "version : $VERSION\n"; exit -1 },
#seqret qualifiers
	    'sreverse'          =>\$h_job_args{reverse_sequence},
	    'slower'            =>\$h_job_args{lower_case},
	    'supper'            =>\$h_job_args{upper_case},
	    'osformat=s'        =>\$h_job_args{index_format},
	    'ossingle'          =>\$h_job_args{split_sequence},
	    'feature'           =>\$h_job_args{feature},
	    );

#recuperation de la configuration
INITIATION:{
    &usage() if ($help);
    &error('informat requiered') if( &is_null($h_job_args{source_format}) );
    &error('outinput requiered') if( &is_null($h_job_args{source_pattern}) );
}


 ENVIRONMENT: {
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
     &MigaleBiomaj::make_directory( $h_job_args{index_dir} );
     chdir $h_job_args{index_dir};

     &MigaleBiomaj::drmaa_initiation() if( $h_job_args{batch_system} eq 'drmaa' );
     &MigaleBiomaj::make_directory( $h_job_args{log_dir} );

#parse la ligne de commande outinput et cree un hash     
     &MigaleBiomaj::string2hash( $h_job_args{source_pattern}, \%h_pattern );
 }

#construction du tableau d'arguments pour les arguments stables sur l'ensemble des jobs
ARGUMENTS:{
    @t_job_args = ( '-sformat', $h_job_args{source_format}, '-osformat', $h_job_args{index_format}, '-auto' );
    @t_job_args = ( @t_job_args, '-sreverse' ) if( $h_job_args{reverse_sequence} );
    @t_job_args = ( @t_job_args, '-slower' )   if( $h_job_args{lower_case} );
    @t_job_args = ( @t_job_args, '-supper' )   if( $h_job_args{upper_case} );
    @t_job_args = ( @t_job_args, '-ossingle' ) if( $h_job_args{split_sequence} );
    @t_job_args = ( @t_job_args, '-feature' )  if( $h_job_args{feature} );
}


#Conversion vers ncbi (par defaut)	 
 CONVERSION:{
     my ( $error, $index_file, $source_file, $file_list, $fh );
     my ( %h_files );
     my ( @t_task_args, @t_file_list, @t_jobid_session );

     &MigaleBiomaj::select_file( $h_job_args{source_dir}, \%h_pattern, \%h_files );

     while( ($index_file, $source_file) = each(%h_files) ) {
	 &debug('Variable>%h_pattern : '.$index_file.' = '.$source_file) if($debug);
	 
	 $index_file = $h_job_args{index_dir} . basename $index_file ;
	 @t_file_list = split ' ', $source_file;

	 ($fh, $file_list) = tempfile(DIR => $h_job_args{log_dir}, UNLINK => 0);

	 if( scalar(@t_file_list) > 1) {
	     for(@t_file_list) {
		 print $fh $_."\n";
	     }

	     @t_task_args = ( @t_job_args, '-outseq', (basename $index_file), '-sequence', "\@$file_list" );
	     $h_job_args{argv} = \@t_task_args;
	     $h_job_args{remote_command} = "$h_job_args{binary_path}/$h_job_args{seqret}";
	     $h_job_args{job_name} = $h_job_args{index_name}.'.'.basename($index_file);

	     push( @t_jobid_session, &MigaleBiomaj::execution_factory(\%h_job_args) );
	     &info('');
	 }

	 elsif( $h_job_args{source_format} eq $h_job_args{index_format} ) {
	     chop $source_file;
	     $error = symlink File::Spec->abs2rel($source_file, $h_job_args{index_dir}), (basename $index_file);
	     &error('symlink error : '.$error.' '.$!) if($error != 1); #1 = succes pour symlink
	 }

	 else {
	     @t_task_args = ( @t_job_args, '-outseq', (basename $index_file), '-sequence', $source_file );
	     $h_job_args{argv} = \@t_task_args;
	     $h_job_args{remote_command} = "$h_job_args{binary_path}/$h_job_args{seqret}";
	     $h_job_args{job_name} = $h_job_args{index_name}.'.'.basename($index_file);
    
	     push( @t_jobid_session, &MigaleBiomaj::execution_factory(\%h_job_args) );
	     &info('');
	 }
     }
     &MigaleBiomaj::drmaa_synchronization( \@t_jobid_session )                          if( $h_job_args{batch_system} eq 'drmaa' );
     &MigaleBiomaj::output_file( $h_job_args{index_dir}, \%h_pattern, 'dependence', 1 ) if( $h_job_args{biomaj} );
     &MigaleBiomaj::print_output_files()                                                if( $h_job_args{biomaj} );
     exit 0;
 }


sub usage() {

      print <<"USAGE";

build_fasta.pl version $VERSION

Standard qualifiers:
  -outinput       Association between output and input. [filename_out=pattern_in]
                  <ncbi_file>=<filename>,[<ncbi_fileN=filenameN>]
		  <*extension>=<filename>,[<*extensionN>=<filenameN>] '*' get the basename of the file(s) without extension
  -informat       Format of the input file(s) [ncbi|genbank|embl|swiss|gcg...]
                  more information in emboss seqret help

BioMaJ qualifiers:
  -biomaj         Execution in BioMaJ session. [Boolean] 
                  default = 0, standalone

Standalone qualifiers:        
  -outdir         Directory of output files. [Directory Path]
                  Requiered in standalone mode
  -indir          Directory of input files. [Directory Path]
                  Requiered in standalone mode
 
Optional qualifiers:
  -execute        Type of execution. [local|drmaa|debug]
                  default = in migale_biomaj.cfg
  -inname         Name of the input directory in the databank directory. [string] Optional
                  Only in BioMaJ session
                  default = source_name in migale_biomaj.cfg
  -outname        Name of the output directory in the databank directory. [string] Optional
                  Only in BioMaJ session
                  default = index_name in migale_biomaj.cfg

Other qualifiers:
  -help           Display this message. [boolean]
  -debug          Display debug messages. [boolean]
                  default = in migale_biomaj.cfg

Seqret qualifiers:
  -sreverse       Use the reverse complement of a nucleic acid sequence. [boolean]
                  default = 0
  -slower         Convert the sequence to lower case. [boolean]
                  default = 1
  -supper         Convert the sequence to upper case. [boolean]
                  default = 0
  -osformat       Specify the output sequence format. [ncbi|genbank|embl|swiss|gcg...]
                  more information in emboss seqret help
                  default = ncbi
  -ossingle       Write each entry into a separate file. [boolean]
                  default = 0
  -feature        Use feature information. [boolean]
                  default = 0

USAGE
   
    exit -1;
}

__END__

=pod

=head1 NAME

B<build_fasta.pl> - Script permettant de convertir les fichiers plat d'un format vers un autre via le programme 'seqret' de la suite EMBOSS.

=head1 VERSION

Version 0.5 (December 2007)

=head1 USAGE

=head2 Conversion de Genbank vers un format NCBI

=head3 Session BioMaJ

S<build_fasta.pl --biomaj --informat genbank --outinput genbank.fasta=gb*.seq,gb_bct.fasta=gbbct*.seq>

Le script genere un fichier genbank.fasta contenant toutes les sequences de Genbank au format fasta-ncbi et de meme pour les sequences contenues dans gbbct*.seq.

=head3 Session Standalone

S<build_fasta.pl --outdir /db/genbank/fasta/ --indir /db/genbank/flat/ --informat genbank --outinput genbank.fasta=gb*.seq,gb_bct.fasta=gbbct*.seq>

Le script va chercher les fichiers dans /db/genbank/flat/ et la sortie se fait dans /db/genbank/fasta/.

=head2 Cas d'une banque etant deja au format ncbi

S<build_fasta.pl --biomaj --informat ncbi --outinput nr.fasta=nr>

Le script genere un lien symbolique nr.fasta qui pointe vers nr

=head2 Cas d'une banque etant deja au format NCBI avec beaucoup de fichiers

S<build_fasta.pl --biomaj --informat ncbi --outinput *.fasta=NC_*.ffn>

Le script genere pour chaque fichier correspondant au pattern 'NC_*.ffn' un lien symbolique 'NC_*.fasta'. Le caractere '*' dans la partie gauche indique qu'il faut reprendre le nom du fichier initial sans son extension.

=head1 DESCRIPTION

B<build_fasta.pl>

- Conversion par defaut vers le format ncbi

- Conversion fichier par fichier ou concatenation de N fichier en un seul

- Creation de liens avec la possibilite de modifier l'extension


=head1 REQUIRED ARGUMENTS

=head2 Standard qualifiers

  -outinput       Association between output and input. [filename_out=pattern_in]
                  ncbi_file=filename,[ncbi_fileN=filenameN]
                  *.extension=filename,[*extensionN=filenameN] '*' get the basename of the file(s) without extension

  -informat       Format of the input file(s) [ncbi|genbank|embl|swiss|gcg...]
                  more information in emboss seqret help

=head2 BioMaJ qualifiers

  -biomaj         Execution in BioMaJ session. [Boolean] 
                  default = 0, standalone

=head2 Standalone qualifiers

  -outdir         Directory of output files. [Directory Path]
                  Requiered in standalone mode

  -indir          Directory of input files. [Directory Path]
                  Requiered in standalone mode

=head1 OPTIONS

=head2 Optional qualifiers

  -execute        Mode d\'execution du programme. [local|drmaa|debug]
                  default = in migale_biomaj.cfg
  -inname         Name of the input directory in the databank directory. [string] Optional
                  Only in BioMaJ session
                  default = source_name in migale_biomaj.cfg
  -outname        Name of the output directory in the databank directory. [string] Optional
                  Only in BioMaJ session
                  default = index_name in migale_biomaj.cfg

=head2 Other qualifiers

  -help           Display this message. [boolean]

  -debug          Display debug messages. [boolean]
                  default = in migale_biomaj.cfg

=head2 Seqret qualifiers

  -sreverse       Use the reverse complement of a nucleic acid sequence. [boolean]
                  default = 0

  -slower         Convert the sequence to lower case. [boolean]
                  default = 1

  -supper         Convert the sequence to upper case. [boolean]
                  default = 0

  -osformat       Specify the output sequence format. [ncbi|genbank|embl|swiss|gcg...]
                  more information in emboss seqret help
                  default = ncbi

  -ossingle       Write each entry into a separate file. [boolean]
                  default = 0

  -feature        Use feature information. [boolean]
                  default = 0

=head1 EXIT STATUS

Exit E<gt>0 : erreur lors de l'indexation

=head1 CONFIGURATION

=head2 Fichier de configuration

C<migale_biomaj.cfg> dans le repertoire conf/process/

=head2 Section [fasta]

=head3 Obligatoire

index_name : nom du repertoire ou seront entreposes les fichiers fasta

source_name : nom du repertoire utilise pour generer les fichiers fasta

binary_path : chemin absolu du repertoire des binaires EMBOSS

seqret : nom du programme seqret dans le repertoire binaires EMBOSS

=head3 Optionnel

cluster_option : options du cluster specifiques a build_fasta.pl

batch_system : type d'execution par defaut pour build_fasta.pl

=head1 DEPENDENCIES

=head2 Modules Perl

warnings, diagnostics, strict

Getopt::Long, File::Basename, File::Temp, File::Spec

MigaleBiomaj

=head2 Programmes externes

=over

=item EMBOSS 5.0

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

=cut

