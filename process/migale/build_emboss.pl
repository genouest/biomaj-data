#!/local/perl/5.8.8/bin/perl
use warnings;
use diagnostics;
use strict;

use Getopt::Long;
Getopt::Long::Configure( 'no_ignorecase' );

use lib ("$ENV{PATH_PROCESS_BIOMAJ}/migale");
use MigaleBiomaj;
use File::Basename;
use Date::Format;
use File::Path;

#use Data::Dumper;
#use File::Spec;
#use File::Glob;

#variables communes aux scripts
my ( $help, $debug );
my ( %h_pattern, %h_job_args );
my ( @t_job_args, @t_jobid_session, @t_task_args );
$h_job_args{biomaj} = 0;

#variables specifiques a ce script
$h_job_args{date} = time2str('%y-%m-%d', time);

#Constantes
my $VERSION = '0.6';

&MigaleBiomaj::read_config( \%h_job_args, 'emboss' );

GetOptions (
#standard qualifiers
	    'outinput=s'       =>\$h_job_args{source_pattern},
	    'informat=s'       =>\$h_job_args{source_format},
	    'program=s'        =>\$h_job_args{remote_command},
#standalone qualifiers
	    'indir=s'          =>\$h_job_args{source_dir},
	    'outdir=s'         =>\$h_job_args{index_dir},
#biomaj qualifiers
	    'biomaj'           =>\$h_job_args{biomaj},
#optional qualifiers
	    'execute=s'        =>\$h_job_args{batch_system},
#other qualifiers
	    'help|h'           =>\$help,
	    'debug'            =>\$debug,
	    'version'           =>sub{ print "version : $VERSION\n"; exit -1 },
#emboss qualifiers
	    'dbname=s'         =>\$h_job_args{databank},
	    'dbresource=s'     =>\$h_job_args{dbresource},
	    'fields=s'         =>\$h_job_args{fields},
	    'release=s'        =>\$h_job_args{release},
	    'date=s'           =>\$h_job_args{date},
	    'exclude=s'        =>\$h_job_args{filename_exclude},
	    'verbose'          =>\$h_job_args{emboss_verbose},
	    'warning'          =>\$h_job_args{emboss_warning},
	    'error'            =>\$h_job_args{emboss_error},
	    );

#recuperation de la configuration
 INITIATION:{
     &usage() if( $help );
 }

 ENVIRONMENT: {
     my ( @t_old_files );

#mise en place de l'environnement dans une session BioMaJ
     if( $h_job_args{biomaj} ) {	 
	 &info('Load : BioMaJ Environment.');
	 &MigaleBiomaj::biomaj_environment( \%h_job_args );
     }
#mise en place de l'environnement dans une session Standalone
     elsif( ( defined $h_job_args{source_dir} ) && ( defined $h_job_args{index_dir} ) ) {
	 &error('dbname requiered') if( &is_null($h_job_args{databank}) );
	 &info('Load : StandAlone Environment.');
	 &MigaleBiomaj::standalone_environment( \%h_job_args );
     }
#probleme donc sortie en usage()
     else {
	 &usage();
     }
#mise en place commune aux deux modes d'execution
     mkpath($h_job_args{index_dir}, {verbose => 1});
     chdir $h_job_args{index_dir};

     &MigaleBiomaj::drmaa_initiation() if( $h_job_args{batch_system} eq 'drmaa' );
     mkpath($h_job_args{log_dir}, {verbose => 1});
#parse la ligne de commande outinput et cree un hash     
     &MigaleBiomaj::string2hash($h_job_args{source_pattern},\%h_pattern) if( defined $h_job_args{source_pattern} );
}

#gestion de la banque rebase
REBASE:{
    last if( $h_job_args{databank} !~ /rebase/i );

    @t_task_args = ( '-infile', $h_job_args{source_dir}.'/withrefm.*', '-protofile', $h_job_args{source_dir}.'/proto.*' );
    $h_job_args{argv} = \@t_task_args;
    $h_job_args{remote_command} =  $h_job_args{binary_path}.'/'. $h_job_args{rebaseextract};
    $h_job_args{job_name} = $h_job_args{index_name}.'.rebase';
    
    push @t_jobid_session, (&MigaleBiomaj::execution_factory(\%h_job_args) );

    &MigaleBiomaj::drmaa_synchronization( \@t_jobid_session )                          if( $h_job_args{batch_system} eq 'drmaa' );
    &MigaleBiomaj::output_file( $h_job_args{index_dir}, \%h_pattern, 'dependence', 1 ) if( $h_job_args{biomaj} == 1 );
    &MigaleBiomaj::print_output_files()                                                if( $h_job_args{biomaj} == 1 );
    exit 0;
}

#gestion de la banque prosite
 PROSITE:{
     last if( $h_job_args{databank} !~ /prosite/i );
     
     @t_task_args = ( '-prositedir', $h_job_args{source_dir} );
     $h_job_args{argv} = \@t_task_args;
     $h_job_args{remote_command} =  $h_job_args{binary_path}.'/'. $h_job_args{prosextract};
     $h_job_args{job_name} = $h_job_args{index_name}.'.prosite';
     
     push( @t_jobid_session, &MigaleBiomaj::execution_factory(\%h_job_args) );
     
     &MigaleBiomaj::drmaa_synchronization( \@t_jobid_session )                          if( $h_job_args{batch_system} eq 'drmaa' );
     &MigaleBiomaj::output_file( $h_job_args{index_dir}, \%h_pattern, 'dependence', 1 ) if( $h_job_args{biomaj} == 1 );
     &MigaleBiomaj::print_output_files()                                                if( $h_job_args{biomaj} == 1 );
     exit 0;
 }

#gestion de la banque PRINTS
PRINTS:{
     last if( $h_job_args{databank} !~ /prints/i );
     
     @t_task_args = ( '-infile', $h_job_args{source_dir}.'/prints*.dat' );
     $h_job_args{argv} = \@t_task_args;
     $h_job_args{remote_command} =  $h_job_args{binary_path}.'/'. $h_job_args{printsextract};
     $h_job_args{job_name} = $h_job_args{index_name}.'.prints';
     
     push( @t_jobid_session, &MigaleBiomaj::execution_factory(\%h_job_args) );
     
     &MigaleBiomaj::drmaa_synchronization( \@t_jobid_session )                          if( $h_job_args{batch_system} eq 'drmaa' );
     &MigaleBiomaj::output_file( $h_job_args{index_dir}, \%h_pattern, 'dependence', 1 ) if( $h_job_args{biomaj} == 1 );
     &MigaleBiomaj::print_output_files()                                                if( $h_job_args{biomaj} == 1 );
     exit 0;
 }


#configuration des programmes
 PROGRAM_FACTORY:for( $h_job_args{remote_command} ) {
     /dbiflat/i && do {
	 $h_job_args{fields} = 'acc,sv,des,key,org' if( &is_null($h_job_args{fields}) );
	 $h_job_args{remote_command} =  $h_job_args{binary_path}.'/'. $h_job_args{dbiflat};
	 last;
     };
     /dbxflat/i && do {
	 $h_job_args{fields} = 'id,acc,sv,des,key,org' if( &is_null($h_job_args{fields}) );
	 $h_job_args{remote_command} =  $h_job_args{binary_path}.'/'. $h_job_args{dbxflat};
         last;
     };
     /dbifasta/i && do {
	 $h_job_args{fields} = 'acc,sv,des' if( &is_null($h_job_args{fields}) );
	 $h_job_args{remote_command} =  $h_job_args{binary_path}.'/'. $h_job_args{dbifasta};
	 last;	 
     };
     /dbxfasta/i && do {
	 $h_job_args{fields} = 'id,acc,sv,des' if( &is_null($h_job_args{fields}) );
	 $h_job_args{remote_command} =  $h_job_args{binary_path}.'/'. $h_job_args{dbxfasta};
	 last;
     };
     /dbigcg/i && do {
	 $h_job_args{fields} = 'acc,sv,des,key,org' if( &is_null($h_job_args{fields}) );
	 $h_job_args{remote_command} =  $h_job_args{binary_path}.'/'. $h_job_args{dbigcg};
	 last;
     };

     /dbxgcg/i && do {
	 $h_job_args{fields} = 'id,acc,sv,des,key,org' if( &is_null($h_job_args{fields}) );
	 $h_job_args{remote_command} =  $h_job_args{binary_path}.'/'. $h_job_args{dbxgcg};
	 last;
     };
     die 'Unknown program';
 }

#construction du tableau d'arguments pour les arguments stables sur l'ensemble des jobs
 ARGUMENTS:{
#verif des options
     &error('outdir path requiered') if( &is_null($h_job_args{index_dir}) );
     &error('release requiered')     if( &is_null($h_job_args{release}) );
     &error('outinput requiered')    if( &is_null($h_job_args{source_pattern}) );
     &error('informat requiered')    if( &is_null($h_job_args{source_format}) );
     &error('program requiered')     if( &is_null($h_job_args{remote_command}) );

     @t_job_args = ( '-release', &short_release( $h_job_args{release} ), '-directory', $h_job_args{source_dir} );
     @t_job_args = ( @t_job_args, '-fields', $h_job_args{fields},'-idformat', $h_job_args{source_format}, '-auto' );

     @t_job_args = ( @t_job_args, '-dbresource', $h_job_args{dbresource} )    if( $h_job_args{remote_command} =~ m/dbx.*$/ );
     @t_job_args = ( @t_job_args, '-exclude', $h_job_args{filename_exclude} ) if( defined $h_job_args{filename_exclude} );
     @t_job_args = ( @t_job_args, '-verbose' )                                if( defined $h_job_args{emboss_verbose} );
     @t_job_args = ( @t_job_args, '-warning' )                                if( defined $h_job_args{emboss_warning} );
     @t_job_args = ( @t_job_args, '-error' )                                  if( defined $h_job_args{emboss_error} );
 }

#gestion des banques autres que prosite et rebase
 MAIN: {
     my ( $logical, $files );

     while( ($logical, $files) = each(%h_pattern) ) {
	 &debug('Variable>%h_pattern : '.$logical.' = '.$files) if($debug);

	 @t_task_args = ( @t_job_args, '-dbname', $logical, '-filenames',$files );

#creation d'un repertoire specifique a chaque division pour l'appli dbi*
	 if( $h_job_args{remote_command} =~ m/dbi.*$/ ) {
	     &MigaleBiomaj::make_directory( $h_job_args{index_dir}.'/'.$logical );
	     @t_task_args = ( @t_task_args, '-indexoutdir', $h_job_args{index_dir}.$logical );
	     @t_task_args = ( @t_task_args, '-outfile', $h_job_args{log_dir}.$logical.'.dbiflat' )
	 }
	 else {
	     @t_task_args = ( @t_task_args, '-indexoutdir', $h_job_args{index_dir} );
             #@t_task_args = ( @t_task_args, '-indexoutdir', '/tmp/uniprot' );
	 }

	 $h_job_args{argv} = \@t_task_args;
	 $h_job_args{job_name} = $h_job_args{index_name}.'.'.basename($logical);
	 
	 push( @t_jobid_session, &MigaleBiomaj::execution_factory(\%h_job_args) );
	 &info('');
     }
     &MigaleBiomaj::drmaa_synchronization( \@t_jobid_session )                          if( $h_job_args{batch_system} eq 'drmaa' );
     &MigaleBiomaj::output_file( $h_job_args{index_dir}, \%h_pattern, 'dependence', 1 ) if( $h_job_args{biomaj} == 1 );
     &MigaleBiomaj::print_output_files()                                                if( $h_job_args{biomaj} == 1 );
     exit 0;
 }
&error('Unknown error : end of the script');

sub short_release() {
    my ($release);

    $release = shift;
    $release =~ m/^[0-9]{2}([0-9]{2}-[0-9]+-[0-9]+)$/;
    return $1 if( defined $1 );
    return $release;
}

sub usage() {

      print <<"USAGE";

build-emboss.pl version $VERSION

Standard qualifiers:
  --outinput       Association between output and input. [dbname=pattern_in]
                   <dbname>=<filename>,[<dbnameN=filenameN>]
  --program        Index program. [dbiflat,dbifasta,dbigcg,dbxflat,dbxfasta,dbxgcg]
                   Not requiered for REBASE,PROSITE and PRINTS.
  --informat       Format of sources files. 
                   *flat  : [SWISS*,REFSEQ,GB,EMBL]
		   *gcg   : [SWISS*,GENBANK,EMBL,PIR]
		   *fasta : [simple,idacc*,gcgid,gcgidacc,dbid,ncbi]
		   Not requiered for REBASE and PROSITE.

BioMaJ qualifiers:
  --biomaj         Execution in BioMaJ session. [Boolean] 
                   default = 0, standalone

Standalone qualifiers:        
  --outdir         Directory of output files. [Directory Path]
                   Requiered in standalone mode
  --indir          Directory of input files. [Directory Path]
                   Requiered in standalone mode
  --dbname         Database name. [string]
                   Required in standalone mode
 
Optional qualifiers:
  --execute        Mode d\'execution du programme. [local|drmaa|debug]
                   default = in migale_biomaj.cfg
  -inname          Name of the input directory in the databank directory. [string] Optional
                   Only in BioMaJ session
                   default = source_name in migale_biomaj.cfg
  -outname         Name of the output directory in the databank directory. [string] Optional
                   Only in BioMaJ session
                   default = index_name in migale_biomaj.cfg

Other qualifiers:
  --help           Display this message. [boolean]
  --debug          Display debug messages. [boolean]
                   default = in migale_biomaj.cfg

Emboss qualifiers:
  --dbresource      Resource name. [string]
                    Only for dbx* program
	  	    default = in migale_biomaj.cfg
  --fields          Index fields.
                    default dbxflat/dbxgcg : id,acc,sv,des,key,org
		    default dbiflat/dbigcg : acc,sv,des,key,org
		    default dbxfasta : id,acc,sv,des
		    default dbifasta : acc,sv,des
  --release         Release number. [string]
                    default = 0.0
		    default in BioMaJ = remote release extracted by BioMaJ
  --date            Index date. [dd/mm/yy]
                    default = 00/00/00
		    default in BioMaJ = $h_job_args{date}
  --exclude         Wildcard filename(s) to exclude. [string]
  --verbose         Report some/full command line options. [boolean]
                    default = 0
  --warning         Report warnings. [boolean]
                    default = 0
  --error           Report errors. [boolean]
                    default = 0

USAGE
   
    exit -1;
}

__END__

=pod

=head1 NAME

B<build_emboss.pl> - EMBOSS indexation of databanks in BioMaJ workflow or in standalone mode.

=head1 VERSION

Version 0.6
Date January 2008

=head1 USAGE

=head2 NR indexation

=head3 Session BioMaJ

C<build_emboss.pl --biomaj --outinput nr=nr --program dbxfasta --informat ncbi>

=head3 Session Standalone

C<build_emboss.pl --outdir /db/nr/emboss/ --indir /db/nr/flat/ --outinput nr=nr --dbname nr --release 07-11-12 --program dbxfasta --informat ncbi>

=head2 REBASE and PROSITE indexation

=head3 Session BioMaJ

C<build_emboss.pl --biomaj --dbname rebase>

C<build_emboss.pl --biomaj --dbname prosite>

'--dbname' parameter is necessary if the databank name in BioMaJ configuration isn't 'rebase' or 'prosite'

=head3 Session Standalone

C<build_emboss.pl --dbname rebase --indir /db/rebase/future_release/flat/>

C<build_emboss.pl --dbname prosite --indir /db/prosite/future_release/flat/>


=head1 DESCRIPTION

B<build_emboss.pl>

=over

=item Support all EMBOSS indexation program excepted 'dbiblast'

=item Support REBASE, PRINTS and PROSITE databanks

=back

=head1 REQUIRED ARGUMENTS


Standard qualifiers:
  --outinput       Association between output and input. [dbname=pattern_in]
                   <dbname>=<filename>,[<dbnameN=filenameN>]
  --program        Index program. [dbiflat,dbifasta,dbigcg,dbxflat,dbxfasta,dbxgcg]
                   Not requiered for REBASE, PROSITE and PRINTS.

BioMaJ qualifiers:
  --biomaj         Execution in BioMaJ session. [Boolean] 
                   default = 0, standalone

Standalone qualifiers:        
  --outdir         Directory of output files. [Directory Path]
                   Requiered in standalone mode
  --indir          Directory of input files. [Directory Path]
                   Requiered in standalone mode
  --dbname         Database name. [string]
                   Required in standalone mode

=head1 OPTIONS

Optional qualifiers:
  --execute        Mode d'execution du programme. [local|drmaa|debug]
                   default = in migale_biomaj.cfg
  --informat       Format of sources files. 
                   *flat  : [SWISS*,REFSEQ,GB,EMBL]
                   *gcg   : [SWISS*,GENBANK,EMBL,PIR]
                   *fasta : [simple,idacc*,gcgid,gcgidacc,dbid,ncbi]
                   Not requiered for REBASE and PROSITE.
  --inname         Name of the input directory in the databank directory. [string] Optional
                   Only in BioMaJ session
                   default = source_name in migale_biomaj.cfg
  --outname        Name of the output directory in the databank directory. [string] Optional
                   Only in BioMaJ session
                   default = index_name in migale_biomaj.cfg

Other qualifiers:
  --help           Display this message. [boolean]
  --debug          Display debug messages. [boolean]
                   default = in migale_biomaj.cfg

Emboss qualifiers:
  --dbresource      Resource name. [string]
                    Only for dbx* program
                    default = in migale_biomaj.cfg
  --fields          Index fields.
                    default dbxflat/dbxgcg : id,acc,sv,des,key,org
                    default dbiflat/dbigcg : acc,sv,des,key,org
                    default dbxfasta : id,acc,sv,des
                    default dbifasta : acc,sv,des
  --release         Release number. [string]
                    default = 0.0
                    default in BioMaJ = remote release extracted by BioMaJ
  --date            Index date. [dd/mm/yy]
                    default = 00/00/00
                    default in BioMaJ = $h_job_args{date}
  --exclude         Wildcard filename(s) to exclude. [string]
  --verbose         Report some/full command line options. [boolean]
                    default = 0
  --warning         Report warnings. [boolean]
                    default = 0
  --error           Report errors. [boolean]
                    default = 0

=head1 EXIT STATUS

Exit E<gt>0 : erreur lors de l'indexation

=head1 CONFIGURATION

Fichier de configuration : migale_biomaj.cfg

=head2 Section : [emboss]

index_name : nom du repertoire stockant les index emboss.
source_name : nom du repertoire stockant les fichier source, flat ici.

Champs optionnels
cluster_option : options du clsuter specifique a emboss.
batch_system=drmaa : mode d'execution par defaut pour emboss.

binary_path : chemin absolue vers le repertoire contenant les binaires emboss

seqret=seqret

rebaseextract=rebaseextract
prosextract=prosextract
printsextract=printsextract

dbxflat=dbxflat
dbiflat=dbiflat
dbxfasta=dbxfasta
dbifasta=dbifasta
dbxgcg=dbxgcg
dbigcg=dbigcg

dbresource : nom du champs resource a utilise dans le .embossrc ou emboss.default.

=head1 DEPENDENCIES

=head2 Modules Perl
warnings, diagnostics, strict

Getopt::Long, MigaleBiomaj, File::Basename, Date::Format

=head2 EMBOSS

EMBOSS 5.0

=head1 BUGS AND LIMITATIONS

- Le module DRMAAc n'a ete teste que sur le scheduler SGE.
- Pas de support du programme dbiblast

=head1 AUTHOR

Ludovic Legrand L<ludovic.legrand@jouy.inra.fr>

=head1 LICENSE AND COPYRIGHT

Copyright 2007 INRA MIG, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 Fonctions

=head2 short_release

    Title        : short_release
    Usage        : short_release($release)
    Prerequisite : none
    Fonction     : Passe les dates yyy-mm-dd en yy-mm-dd pour les programmes d'indexation EMBOSS sinon il renvoie l'entree sans modification
    Returns      : date au format yy-mm-dd
    Args         : $release : numeros ou date de la release de la banque de donnee.
    Env          : none

=cut


