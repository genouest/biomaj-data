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
my ( @t_job_args, @t_jobid_session, @t_task_args );
$h_job_args{biomaj} = 0;

#variables specifiques a ce script

#Constantes
my $VERSION = '0.5';

&MigaleBiomaj::read_config( \%h_job_args, 'srs' );

GetOptions (
#standard qualifiers
	    'biomaj'	       =>\$h_job_args{biomaj},
	    'databank=s'       =>\$h_job_args{databank},
#optional qualifiers	    	    
	    'execute=s'        =>\$h_job_args{batch_system},
#other qualifiers
	    'debug'            =>\$debug,
	    'help'             =>\$help,
	    'version'            =>sub{ print "version : $VERSION\n"; exit -1 },
	    );

#recuperation de la configuration
 INITIATION: {
     &usage() if ($help);
     &error('-databank requiered')  if( &is_null($h_job_args{databank}) );
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
     &MigaleBiomaj::make_directory($h_job_args{index_dir});
     chdir $h_job_args{index_dir};

     &MigaleBiomaj::drmaa_initiation() if( $h_job_args{batch_system} eq 'drmaa' );
     &MigaleBiomaj::make_directory($h_job_args{log_dir});

#pose un lock ou attend la fin du lock avant de commencer afin d'eviter de crasher le SRS en cours
     &srs_lock();

#parse la ligne de commande outinput et cree un hash     
     &MigaleBiomaj::string2hash($h_job_args{source_pattern},\%h_pattern) if( defined $h_job_args{source_pattern} );
 }

#check la mise a jour des donnees et genere un make si necessaire
 SRSCHECK:{
     @t_task_args = ('-nomove', '-l', $h_job_args{databank});
     $h_job_args{argv} = \@t_task_args;
     $h_job_args{remote_command} = $h_job_args{binary_path}.'/'. $h_job_args{srscheck};
     $h_job_args{job_name} = $h_job_args{databank}.'.'.$h_job_args{index_name};
     
     push( @t_jobid_session, &MigaleBiomaj::execution_factory(\%h_job_args) );
     &info('');
     &MigaleBiomaj::drmaa_synchronization( \@t_jobid_session ) if( $h_job_args{batch_system} eq 'drmaa' );
 }

#execute le make qui fait l'indexation
 SRSDO:{
     @t_task_args = ('all');
     $h_job_args{argv} = \@t_task_args;
     $h_job_args{remote_command} = $h_job_args{binary_path}.'/'. $h_job_args{srsdo};
     $h_job_args{job_name} = $h_job_args{databank}.'.'.$h_job_args{index_name};

     push( @t_jobid_session, &MigaleBiomaj::execution_factory(\%h_job_args) );
     &info('');
     &MigaleBiomaj::drmaa_synchronization( \@t_jobid_session ) if( $h_job_args{batch_system} eq 'drmaa' );
 }

&MigaleBiomaj::output_file($h_job_args{index_dir}, \%h_pattern, 'dependence', 1 ) if( $h_job_args{biomaj} == 1 );
&MigaleBiomaj::print_output_files() if($h_job_args{biomaj} == 1);
unlink '/tmp/srs.lock';
exit 0;

sub srs_lock() {
    if( -e '/tmp/srs.lock' ) {
	&warning('/tmp/srs.lock existe ... effacer ce fichier si aucune session SRS est en court d\'execution');
	while(1) {
	    &warning('/tmp/srs.lock existe ... prochain essai dans 10 minutes');
	    sleep 600;
	    last if( !-e '/tmp/srs.lock' );
	}
    }
    system('touch /tmp/srs.lock');
}


sub usage() {

print <<"USAGE";

build_srs.pl version $VERSION

Standard qualifiers:
  -databank       Databank name in srsdb.i. [string]

BioMaJ qualifiers:
  -biomaj         Execution in BioMaJ session. [Boolean] 
                  default = 0, standalone

Optional qualifiers:
  -execute        Execution mode. [local|drmaa|debug]
                  default = in migale_biomaj.cfg

Other qualifiers:
  -help           Display this message. [boolean]
  -debug          Display debug messages. [boolean]
                  default = in migale_biomaj.cfg
  -version        Display program version. [boolean]

USAGE
   
    exit -1;
}

__END__

=pod

=head1 NAME

B<build_srs.pl> - Script permettant de generer les index SRS.

=head1 VERSION

Version 0.5 (December 2007)

=head1 USAGE

=head2 Indexation SRS pour la banque Genbank

=head3 Session BioMaJ

C<build_srs.pl --biomaj --databank genbankrelease>

=head3 Session Standalone

C<build_gcg.pl --databank genbankrelease>

=head1 DESCRIPTION

=over

=item Gestion des session multiples de SRS via un lock

=item Indexation complete SRS

=back

=head1 REQUIRED ARGUMENTS

Standard qualifiers:
  -databank       Databank name in srsdb.i. [string]

BioMaJ qualifiers:
  -biomaj         Execution in BioMaJ session. [Boolean] 
                  default = 0, standalone

=head1 OPTIONS

Optional qualifiers:
  -execute        Execution mode. [local|drmaa|debug]
                  default = in migale_biomaj.cfg

Other qualifiers:
  -help           Display this message. [boolean]
  -debug          Display debug messages. [boolean]
                  default = in migale_biomaj.cfg
  -version        Display program version. [boolean]

=head1 EXIT STATUS

Exit E<gt>0 : erreur lors de l'indexation

=head1 CONFIGURATION

=head2 Fichier de configuration

C<migale_biomaj.cfg> dans le repertoire conf/process

=head2 Section [srs]

=head3 Obligatoire

=head3 Optionnel

=head1 DEPENDENCIES

=head2 Modules Perl

warnings, diagnostics, strict

Getopt::Long, MigaleBiomaj, File::Basename

=head2 Programmes externes

=over

=item SRS 8+

=back

=head1 BUGS AND LIMITATIONS

=over

=item - Le module DRMAAc n'a ete teste que sur le scheduler SGE.

=item - La suite SRS n'a pas ete teste sur le cluster

=item - Il faut sourcer l'environnement SRS dans le .bashrc

=item - Il se peut que le lock /tmp/srs.lock ne soit pas correctement efface lors d'une session BioMaJ qui se passe mal.
        Il suffit de deleter ce fichier pour permettre a nouveau l'indexation SRS via ce process.

=back

=head1 AUTHOR

Ludovic Legrand L<ludovic.legrand@jouy.inra.fr>

=head1 LICENSE AND COPYRIGHT

Copyright 2007 INRA MIG, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

