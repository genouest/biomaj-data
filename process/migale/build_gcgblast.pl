#!/usr/bin/perl

use warnings;
use diagnostics;
use strict;

use Getopt::Long;
Getopt::Long::Configure( 'no_ignorecase' );

use lib ("$ENV{BIOMAJ_ROOT}/conf/process");
use MigaleBiomaj;
use File::Basename;

#use Data::Dumper;
#use File::Spec;
#use Date::Format;
#use File::Glob;

#variables communes aux scripts
my ( $help, $error, $debug );
my ( %h_pattern, %h_job_args );
my ( @t_job_args );
$h_job_args{biomaj} = 0;

#variables specifiques a ce script

#Constantes
my $VERSION = '0.5';

&MigaleBiomaj::read_config( \%h_job_args, 'gcgblast' );

GetOptions (
#standard qualifiers
	    'outinput=s'         =>\$h_job_args{source_pattern},
#standalone qualifiers
	    'indir=s'            =>\$h_job_args{source_dir},
	    'outdir=s'           =>\$h_job_args{index_dir},
#biomaj qualifiers
	    'biomaj'             =>\$h_job_args{biomaj},
#optional qualifiers
	    'execute=s'          =>\$h_job_args{batch_system},
	    'inname=s'           =>\$h_job_args{source_name},
	    'outname=s'          =>\$h_job_args{index_name},
#other qualifiers
	    'help'               =>\$help,
	    'debug'              =>\$debug,
	    'version'            =>sub{ print "version : $VERSION\n"; exit -1 },
#gcgblast qualifiers
	    'volsize=i'          =>\$h_job_args{volume_size},
	    'parseseqid'         =>\$h_job_args{parse_seqid},
	    );

#recuperation de la configuration
 INITIATION: {
     &usage() if($help);
     &error('outinput requiered') if( &is_null($h_job_args{source_pattern}) );
 }

ENVIRONMENT: {
    my ( @t_old_files );

#mise en place de l'environnement dans une session BioMaJ
    if( $h_job_args{biomaj} ) {
	&info('Load : BioMaJ Environment.');
	&MigaleBiomaj::biomaj_environment( \%h_job_args );
     }

#mise en place de l'environnement dans une session Standalone
    elsif( defined($h_job_args{source_dir}) && defined($h_job_args{index_dir}) ) {
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

 ARGUMENTS:{
     @t_job_args = ( '-quiet', '-default' );
     @t_job_args = ( @t_job_args, '-volsize', $h_job_args{volume_size} )    if( defined $h_job_args{volume_size} );
     @t_job_args = ( @t_job_args, '-parseseqid', $h_job_args{parse_seqid} ) if( defined $h_job_args{parse_seqid} );

     $h_job_args{remote_command} = $h_job_args{binary_path}.'/'.$h_job_args{formatdb};
 }



#Creation de l'index
 MAIN: {
     my ( $index_file, $source_file );
     my ( @t_jobid_session, @t_task_args );
     
     while( ($index_file, $source_file) = each(%h_pattern) ) {
	 &debug('Variable>%h_pattern : '.$index_file.' = '.$source_file) if($debug);
	 
	 @t_task_args = ( @t_job_args, '-outfile', $index_file, '-infile', $h_job_args{source_dir} . $source_file );
	 
	 $h_job_args{argv} = \@t_task_args;
	 $h_job_args{job_name} = $h_job_args{index_name}.'.'.basename($index_file);

	 push( @t_jobid_session, &MigaleBiomaj::execution_factory(\%h_job_args) );
	 &info('');
     }
     &MigaleBiomaj::drmaa_synchronization( \@t_jobid_session )                         if( $h_job_args{batch_system} eq 'drmaa' );
     &MigaleBiomaj::output_file($h_job_args{index_dir}, \%h_pattern, 'dependence', 1 ) if( $h_job_args{biomaj} == 1 );
     &MigaleBiomaj::print_output_files()                                               if($h_job_args{biomaj} == 1);
 }

sub usage() {

print <<"USAGE";

build_gcgblast.pl version $VERSION

Standard qualifiers:
  -outinput       Association between output and input. [logical_dbname=pattern_in]
                  <logical_dbname>=<filename>,[<logical_dbnameN=filenameN>]

BioMaJ qualifiers:
  -biomaj         Execution in BioMaJ session. [Boolean] 
                  default = 0, standalone

Standalone qualifiers:        
  -outdir         Directory of output files. [Directory Path]
                  Requiered in standalone mode
  -indir          Directory of input files. [Directory Path]
                  Requiered in standalone mode
 
Optional qualifiers:
  -execute        Execution mode. [local|drmaa|debug]
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
  -version        Display program version. [boolean]

Formatdb+ qualifiers:
  -volsize        Sets maximum number of characters per database volume in millions, 0 means single volume). [integer]
                  default = 0
  -parseseqid     Create databases with additional parsed indicies. [boolean]
                  default = true

USAGE
   
    exit -1;
}

__END__

=pod

=head1 NAME

B<build_gcgblast.pl> - Script permettant de generer les index GCGBLAST avec le programme formatdb+.

=head1 VERSION

Version 0.5 (December 2007)

=head1 USAGE

=head2 Indexation GCGBLAST pour la banque Genbank

=head3 Session BioMaJ

C<build_gcgblast.pl --biomaj --outinput genbank=gb*.seq,gb_bct=gbbct*.seq>

=head3 Session Standalone

C<build_gcgblast.pl --outdir /db/genbank/gcgblast/ --indir /db/genbank/flat/ --outinput genbank=gb*.seq,gb_bct=gbbct*.seq>

=head1 DESCRIPTION

=over

=item - Utilisation du programme d'indexation formatdb+

=item - Gestion des options de formatdb+

=item - Different mode d'execution

=back

=head1 REQUIRED ARGUMENTS

Standard qualifiers:
  -outinput       Association between output and input. [logical_dbname=pattern_in]
                  <logical_dbname>=<filename>,[<logical_dbnameN=filenameN>]

BioMaJ qualifiers:
  -biomaj         Execution in BioMaJ session. [Boolean] 
                  default = 0, standalone

Standalone qualifiers:        
  -outdir         Directory of output files. [Directory Path]
                  Requiered in standalone mode
  -indir          Directory of input files. [Directory Path]
                  Requiered in standalone mode
 
=head1 OPTIONS

Optional qualifiers:
  -execute        Execution mode. [local|drmaa|debug]
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
  -version        Display program version. [boolean]

Formatdb+ qualifiers:
  -volsize        Sets maximum number of characters per database volume in millions, 0 means single volume). [integer]
                  default = 0
  -parseseqid     Create databases with additional parsed indicies. [boolean]
                  default = true

=head1 EXIT STATUS

Exit E<gt>0 : erreur lors de l'indexation

=head1 CONFIGURATION

=head2 Fichier de configuration

C<migale_biomaj.cfg> dansd le repertoire conf/process/

=head2 Section [gcgblast]

=head3 Obligatoire

index_name : nom du repertoire stockant les index GCGBLAST

source_name : nom du repertoire stockant les fichiers necessaire a l'indexation GCGBLAST

binary_path : chemin absolu du repertoire contenant les binaires

formatdb : nom du binaire formatdb+

blast : nom du binaire blast+

program_path : chemin absolu du repertoire contenant le programme GCG

=head3 Optionnel

cluster_option : options du cluster specifiques a GCG

batch_system : mode d'execution par defaut pour GCG

=head1 DEPENDENCIES

=head2 Modules Perl

warnings, diagnostics, strict

Getopt::Long, MigaleBiomaj, File::Basename

=head2 Programmes externes

=over

=item GCG 11

=back

=head1 BUGS AND LIMITATIONS

=over

=item - Le module DRMAAc n'a ete teste que sur le scheduler SGE.

=item - La suite GCG n'a pas ete teste sur le cluster

=item - Il faut sourcer l'environnement GCG dans le .bashrc

=back

=head1 AUTHOR

Ludovic Legrand L<ludovic.legrand@jouy.inra.fr>

=head1 LICENSE AND COPYRIGHT

Copyright 2007 INRA MIG, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

