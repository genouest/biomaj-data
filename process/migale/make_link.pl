#!/usr/bin/perl

use warnings;
use diagnostics;
use strict;

use Getopt::Long;
Getopt::Long::Configure( 'no_ignorecase' );

use lib ("$ENV{BIOMAJ_ROOT}/conf/process");
use MigaleBiomaj;
use File::Basename;
use File::Copy;
use File::Spec;

#use Date::Format;
#use File::Glob;
#use Data::Dumper;

#variables communes aux scripts
my ( $help, $error, $debug );
my ( %h_pattern, %h_job_args );
$h_job_args{biomaj} = 0;

#variables specifiques a ce script

#Constantes
my $VERSION = '0.5';

&MigaleBiomaj::read_config( \%h_job_args, '' );

GetOptions (
#standard qualifiers
	    'section=s'     =>\$h_job_args{section_name},
#optionnal qualifiers
	    'directory=s'   =>\$h_job_args{directory_name},
#other qualifiers
	    'debug'         =>\$debug,
	    'help|h'        =>\$help,
	    'version'       =>sub{ print "version : $VERSION\n"; exit -1 },
	    );

#recuperation de la configuration
 INITITATION: {
     &usage() if ($help);
 
     &error('-section requiered')  if( &is_null($h_job_args{section_name}) );

     &MigaleBiomaj::read_config( \%h_job_args, $h_job_args{section_name} );
 }

 ENVIRONMENT:{
     &info('Load : BioMaJ Environment.');
     &MigaleBiomaj::biomaj_environment( \%h_job_args );
 }


 MAIN: {
     my ( $link_path );

     if( defined $h_job_args{directory_name} ) {
	 $link_path =  File::Spec->catdir("$h_job_args{release_path}", "$h_job_args{directory_name}", '*');
     }
     else {
	 $link_path =  File::Spec->catdir("$h_job_args{release_path}", "$h_job_args{index_name}", '*');
     }
	print "$h_job_args{repository}\n";
	print "$link_path\n";

     $error = system("$h_job_args{ln} -sf $link_path $h_job_args{repository}");
     die 'Error - link : '.$! if( $error );
 }

sub usage() {
    print <<"USAGE";

<make_link.pl> - link les fichiers blast/gcgblast dans leur repertoire repository respectif

  --section    Nom de la section a link (blast ou gcgblast par defaut)
  --directory  Nom du repertoire dans la banque a link vers le repository
               defaut = section
  --help       Display that screen.

USAGE

exit -1;
}
