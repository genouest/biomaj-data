package MigaleBiomaj;

BEGIN {
    unless( eval "use Schedule::DRMAAc qw/ :all /; 1" ) {
	warn "Couldn't use Schedule::DRMAAc, cluster interaction will be not possible";
    }
}

use strict;
use warnings;
use diagnostics;

use vars qw(@ISA @EXPORT);
use File::Find;
use File::Basename;
use Data::Dumper;
use File::Spec;
#use Schedule::DRMAAc qw/ :all /;
use Date::Format;
use Config::Simple;
require Exporter;


@ISA = qw(Exporter);
@EXPORT = qw( is_null info warning error debug );

#variables de la librairie
my $CONFIG_FILE = "$ENV{PATH_PROCESS_BIOMAJ}/migale/migale.cfg";
my ($OUTPUT_FILES,$OUTPUT_FILES_VOLATILE) = ("","");
my %h_lib_config;
my $debug;

my $VERSION = '0.6';

#initiation de la librairie
&read_config(\%h_lib_config, 'global' );
&read_config(\%h_lib_config, 'system' );
$debug = $h_lib_config{debug};

=head1 NAME

MigaleBiomaj.pm - Librairie pour les scripts BioMaJ de Jouy-en-Josas.

=head1 VERSION

Version 0.6 (Janvier 2008)

=head1 CONFIGURATION

=head2 Section

[global]

Variables globales pour l'ensemble des scripts.

=head2 Variables

adminmail : adresse email pour le cluster

block_email : blocker l'envoie d'email par le cluster

host : nom/ip de la machine de log

log_path : chemin du repertoire de log (il doit exister)

current_link : nom du lien pour les banques en production

future_release_link : nom du lien pour les banques en indexation

flat_name : non du repertoire stockant les fichiers plats

batch_system : systeme d'execution par defaut

debug : mode debug pour la librairie

=head2 Section

[system]

Chemin des binaires systemes.

=head2 Variables

find : chemin absolu pour le programme find

=head1 DEPENDENCIES

=head2 Modules Perl

warnings, diagnostics, strict, vars, Exporter

File::Basename, File::Find, Data::Dumper, File::Spec, Schedule::DRMAAc, Date::Format, Config::Simple

=head1 BUGS AND LIMITATIONS

- Le module DRMAAc n'a ete teste que sur le scheduler SGE.

=head1 AUTHOR

Ludovic Legrand L<ludovic.legrand@jouy.inra.fr>

=head1 LICENSE AND COPYRIGHT

Copyright 2007 INRA MIG, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 API de MigaleBiomaj.pm

=head2 Procedure d initialisation et de configuration des process BioMaJ

=head3 biomaj_environment

    Title        : biomaj_environment
    Usage        : biomaj_environment(\%h_job_args)
    Prerequisite : none
    Fonction     : Mise en place de l environnement du process pour BioMaJ.
    Returns      : none
    Args         : \%h_job_args : reference du hash contenant les informations sur le process.
    Env          : dbname, datadir, dirversion, remoterelease, PP_DEPENDENCE, PP_DEPENDENCE_VOLATILE, PP_WARNING

=cut

sub biomaj_environment {
    &error('[MigaleBiomaj.pm] biomaj_environment : one arguments requiered') if( scalar(@_) < 1 );

    my ( $h_job_args );
    my ( $future_release_path, $release_path );

    $h_job_args = shift;

#verification des variables d'environnement BioMaJ
    &error("the environment variable 'dbname' is not set.")                 if ( !exists($ENV{'dbname'}) || $ENV{'dbname'} eq ""); 
    &error("the environment variable 'datadir' is not set.")                if ( !exists($ENV{'datadir'}) || $ENV{'datadir'} eq "");
    &error("the environment variable 'dirversion' is not set.")             if ( !exists($ENV{'dirversion'}) || $ENV{'dirversion'} eq "");
    &error("the environment variable 'remoterelease' is not set.")          if ( !exists($ENV{'remoterelease'}) || $ENV{'remoterelease'} eq "");
    &error("the environment variable 'PP_DEPENDENCE' is not set.")          if ( !exists($ENV{'PP_DEPENDENCE'}) || $ENV{PP_DEPENDENCE} eq "");
    &error("the environment variable 'PP_DEPENDENCE_VOLATILE' is not set.") if ( !exists($ENV{'PP_DEPENDENCE_VOLATILE'}) || $ENV{PP_DEPENDENCE_VOLATILE} eq "");
    &error("the environment variable 'PP_WARNING' is not set.")             if ( !exists($ENV{'PP_WARNING'}) || $ENV{PP_WARNING} eq "");

#initiation des paths    
    $h_job_args->{future_release_path} = File::Spec->canonpath( "$ENV{datadir}/$ENV{dirversion}/$h_lib_config{future_release_link}" );
    $h_job_args->{release_path} = File::Spec->canonpath( "$ENV{datadir}/$ENV{dirversion}/$ENV{dbname}_$ENV{remoterelease}" );
    $h_job_args->{databank_path} = File::Spec->canonpath( "$ENV{datadir}/$ENV{dirversion}" );

    $h_job_args->{index_dir} = File::Spec->canonpath( "$h_job_args->{future_release_path}/$h_job_args->{index_name}" ).'/'   if( !defined $h_job_args->{index_dir} );
    $h_job_args->{source_dir} = File::Spec->canonpath( "$h_job_args->{future_release_path}/$h_job_args->{source_name}" ).'/' if( !defined $h_job_args->{source_dir} );
    &error('Error - '.$h_job_args->{source_dir}.' don\'t exist') if( !(-d $h_job_args->{source_dir}) );

    $h_job_args->{date} = time2str('%y-%m-%d', time) if( !defined $h_job_args->{date} );
    $h_job_args->{log_dir} = File::Spec->canonpath( "$h_job_args->{log_path}/$h_job_args->{index_name}_$h_job_args->{date}" ).'/';
    
    &debug('Dump de %h_job_args '.Dumper(%$h_job_args)) if( $debug );

    $h_job_args->{databank} = $ENV{'dbname'}       if( !defined $h_job_args->{databank} );
    $h_job_args->{release} = $ENV{'remoterelease'} if( !defined $h_job_args->{release} );
 }


=head3 standalone_environment

	Title        : standalone_environment
	Usage        : standalone_environment(\%h_job_args)
	Prerequisite : none
	Fonction     : Mise en place de l environnement du pocess en StandAlone.
	Returns      : none
	Args         : \%h_job_args : reference du hash contenant les informations sur le process.
	Env          : 

=cut

sub standalone_environment {
    &error('[MigaleBiomaj.pm] standalone_environment : one arguments requiered') if( scalar(@_) < 1 );
    
    my ( $h_job_args );

    $h_job_args = shift;
    $ENV{'PP_WARNING'} = ' ';
    
    &error('indir path requiered')   if( &is_null($h_job_args->{source_dir}) );
    &error('outdir path requiered')  if( &is_null($h_job_args->{index_dir}) );
    
    $h_job_args->{index_dir} =  File::Spec->rel2abs( $h_job_args->{index_dir} ).'/' if( !defined $h_job_args->{index_dir} );
    $h_job_args->{source_dir} =  File::Spec->rel2abs( $h_job_args->{source_dir} ).'/';
    &error('Error - '.$h_job_args->{source_dir}.' don\'t exist') if( !(-d $h_job_args->{source_dir}) );
    
    $h_job_args->{date} = time2str('%y-%m-%d', time) if( !defined $h_job_args->{date} );
    $h_job_args->{log_dir} = File::Spec->canonpath( "$h_job_args->{log_path}/$h_job_args->{index_name}_$h_job_args->{date}" ).'/';
}

=head3 readCfgFile

	Title        : read_config
	Usage        : read_config($h_config, $section)
	Prerequisite : none
	Fonction     : Lit le fichier de conf $CONFIG_FILE.
	             : Place une Cle/Valeur dans la reference de hash transmis pour chaque ligne CLE=valeur du fichier
	Returns      : none
	Args         : $h_config : reference sur un hash.
                       $section : block du fichier a lire.
	Globals      : $CONFIG_FILE

=cut

sub read_config {
    &error('[MigaleBiomaj.pm] read_config : two arguments requiered') if( scalar(@_) < 2 );

    my ( $h_config, $o_cfg, $section );
    my ( %h_cfg );
    
    $h_config = shift;
    $section = shift;

#lecture du fichier $CONFIG_FILE
    $o_cfg = new Config::Simple($CONFIG_FILE);
#chargement des donnees dans %h_cfg
    %h_cfg = $o_cfg->vars();

#initiation du hash $h_config pour les valeurs global
    while( my($key,$value) = each(%h_cfg) ) {
	$h_config->{$2} = $value if( $key =~ /^(global|system)\.(.*)/  );
    }
#initiation du hash $h_config pour les valeurs specifiques a la $section
    while( my($key,$value) = each(%h_cfg) ) {
	$h_config->{$1} = $value if( $key =~ /^$section\.(.*)/  );
    }
}

=head2 Communication entre les Process et Biomaj

=head3 info

	Title        : info
	Usage        : info($msg)
	Prerequisite : none
	Fonction     : Imprime sur STDOUT un message pour info
	Returns      : none
	Args         : $msg
	Globals      : none

=cut

sub info {
    &error('[MigaleBiomaj.pm] info : one arguments requiered') if( scalar(@_) < 1 );

    my ( $msg );
    
    $msg = shift;
    $msg = '' if( !defined $msg );

    print STDOUT "$msg\n";
}

=head3 warning

	Title        : warning
	Usage        : warning($msg)
	Prerequisite : none
	Fonction     : Imprime sur STDOUT un message warning (Capte par BioMaJ par la balise $ENV{PP_WARNING})
	Returns      : none
	Args         : $msg
	Globals      : none

=cut

sub warning {
    &error('[MigaleBiomaj.pm] warning : one arguments requiered') if( scalar(@_) < 1 );

    my ( $msg );

    $msg = shift;
    $msg = '' if( !defined $msg );

    print STDOUT "$ENV{PP_WARNING}$msg\n";
}

=head3 error

	Title        : error
	Usage        : error($msg)
	Prerequisite : none
	Fonction     : Imprime sur STDERR un message et quitte le programme avec un code de retour -1
	Returns      : none
	Args         : $msg
	Globals      : none

=cut

sub error {
    my ( $msg );
    
    $msg = shift;
    $msg = '' if( !defined $msg );
    
    print STDERR "$msg\n";
    exit(-1);
}


=head3 debug

    	Title        : debug
	Usage        : debug( $msg )
	Prerequisite : none
	Fonction     : Affiche sur STDERR le message de debug avec [DEBUG] en debut de chaine.
	Returns      : none
	Args         : $msg : message
        Globals      : none

=cut

sub debug() {
    &error('[MigaleBiomaj.pm] debug : one arguments requiered') if( scalar(@_) < 1 );
    
    my ($msg);

    $msg = shift;
    $msg = '' if( !defined $msg  );

    print STDERR '[DEBUG]'.$msg."\n"
}


=head3 clear_output_files

	Title        : clear_output_files
	Usage        : clear_output_files($tag)
	Prerequisite : none
	Fonction     : Vide les variables $OUTPUT_FILES et $OUTPUT_FILES_VOLATILE selon $tag
	Returns      : none
	Args         : $tag : ('all', 'dependence' ou 'volatile')
	             : Selon la valeur utilisee, la (les) liste(s) correspondantes sera(ont) vidée(s)
	             : Defaut : 'all'
	Globals      : $OUTPUT_FILES et $OUTPUT_FILES_VOLATILE

=cut

sub clear_output_files {
    &error('[MigaleBiomaj.pm] clear_output_files : one arguments requiered') if( scalar(@_) < 1 );

    my ( $tag );
    
    $tag = shift;
    $tag = 'all' if( (!defined $tag) || ($tag eq '') );
    
    &error("clearOutputFiles($tag) : $tag --> no valid option. ['','dependence','volatile','all']") if( $tag !~ m/(all|volatile|dependence)/ );
    
    if( ($tag eq 'all') || ($tag eq 'volatile') ) {
	$OUTPUT_FILES_VOLATILE = '';
    }
    if( ($tag eq 'all') || ($tag eq 'dependence') ) {
	$OUTPUT_FILES = '';
    }
}


=head3  print_output_files

	Title        : print_output_files
	Usage        : print_output_files()
	Prerequisite : none
	Fonction     : Imprime sur STDOUT les fichiers des listes $OUTPUT_FILES et $OUTPUT_FILES_VOLATILE
	             : avec le tag $ENV{PP_DEPENDENCE} ou $ENV{PP_DEPENDENCE_VOLATILE}
	Returns      : none
	Args         : none
	Globals      : $OUTPUT_FILES et $OUTPUT_FILES_VOLATILE

=cut

sub print_output_files {
    my ( $ofile );

    if ( $OUTPUT_FILES ne '' ) {
	foreach $ofile (split /\s+/, $OUTPUT_FILES) {
	    print STDOUT "$ENV{PP_DEPENDENCE}$ofile\n";
	}
    }
	
    if ( $OUTPUT_FILES_VOLATILE ne '' )	{
	foreach $ofile (split /\s+/, $OUTPUT_FILES_VOLATILE) 	{
	    print STDOUT "$ENV{PP_DEPENDENCE_VOLATILE}$ofile\n";
	}
    }
}

=head3 output_file

    	Title        : output_file
	Usage        : output_file( $directory, $h_pattern, $type, $maxdepth )
	Prerequisite : none
	Fonction     : Declare les fichiers d index a BioMaJ
	Returns      : none
	Args         : $directory : chemin du repertoire de l index
                       $h_pattern : reference au hash contenant les patterns outinput
                       $type :      volatile ou dependence
                       $maxdepth :  profondeur a explorer pour trouver les fichiers d index dans le repertoire
        Globals      : none

=cut

sub output_file() {
    &error('[MigaleBiomaj.pm] output_file : four arguments requiered') if( scalar(@_) < 4 );

    my ( $directory, $key, $value, $h_pattern, $type, $maxdepth );
    my ( @t_files );

    $type = 'dependence';
    ( $directory, $h_pattern, $type, $maxdepth ) = ( shift, shift, shift, shift );
    $directory = File::Spec->rel2abs( $directory );

    &error('[MigaleBiomaj.pm] output_file : No valide option (volatile or dependence)') if( $type !~ m/(volatile|dependence)/i );

    while( ($key, $value) = each(%$h_pattern) ) {
	@t_files = `find $directory -name "$key*" -maxdepth $maxdepth`;

	for(@t_files) {
	    $OUTPUT_FILES .= "$_ "          if ( ($type =~ m/^dependence$/i) && ($OUTPUT_FILES !~ m/$_/ ) );
	    $OUTPUT_FILES_VOLATILE .= "$_ " if ( ($type =~ m/^volatile$/i) && ($OUTPUT_FILES_VOLATILE !~ m/$_/ ) );
	}
    }
    &debug('[MigaleBiomaj.pm] output_file($OUTPUT_FILES) : '.Dumper($OUTPUT_FILES) ) if( $debug );
    &debug('[MigaleBiomaj.pm] output_file($OUTPUT_FILES_VOLATILE) : '.Dumper($OUTPUT_FILES_VOLATILE) ) if( $debug );
}

=head2 Fonctions utilitaires

=head3  make_directory

	Title        : make_directory
	Usage        : make_directory($directory)
	Prerequisite : none
	Fonction     : Creation d un répertoire avec un message d information.
	Returns      : Chemin absolue du repertoire.
	Args         : $directory : chemin du repertoire a creer.
	Globals      : none

=cut

sub make_directory() {
    &error('[MigaleBiomaj.pm] make_directory : one arguments requiered') if( scalar(@_) < 1 );

    my ( $directory );

    $directory = shift;
    $directory = File::Spec->rel2abs( $directory );
    
    &error("$directory don't defined") if ( (!defined $directory) || ($directory eq '') );
    printf("dir:%s\n",$directory);
    if ( !-e $directory ) {
	if ((mkdir $directory)) {
	    &warning("mkdir $directory");
	}
	else {
	    &error("directory n'a pas pu etre créé : $!") if( !-e $directory );
	}
    }
    return $directory;
}


=head3 is_null

    	Title        : is_null
	Usage        : is_null( $variable )
	Prerequisite : none
	Fonction     : Test si la variable est indefini ou null.
	Returns      : 0 : variable non nulle
                       1 : variable nulle
	Args         : $variable
        Globals      : none

=cut

sub is_null() {
    &error('[MigaleBiomaj.pm] is_null : one arguments requiered') if( scalar(@_) < 1 );
    
    my ( $variable );

    $variable = shift;
    
    return 1 if( !(defined $variable) || ($variable eq '') );
    return 0;
}


=head3 select_file

    	Title        : select_file
	Usage        : select_file( $source_dir, $h_pattern, $h_files )
	Prerequisite : none
	Fonction     : Gere la recuperation des chemin absolue des fichiers a partir des patterns fournis
                       dans l option outinput. Cette fonction ne sert que pour la creation des liens
                       symboliques dans build_fasta.pl.
	Returns      : none
	Args         : $source_dir : Chemin du repertoire ou se situe les fichiers
                       $h_pattern : reference au hash contenant les patterns outinput
                       $h_files : reference au hash contenant les fichiers correspondants aux patterns
        Globals      : none

=cut

sub select_file() {
    &error('[MigaleBiomaj.pm] select_file : three arguments requiered') if( scalar(@_) < 3 );

    my ( $directory, $h_pattern, $h_files, $new_file, $old_file, $temp_new_file );
    my ( @t_files);
    my ( $extension );

    ( $directory, $h_pattern, $h_files) = ( shift, shift, shift);
    $extension = '';

    while( ($new_file, $old_file) = each(%$h_pattern) ) {
	&debug('Variable>%h_files : '.$new_file.' = '.$old_file) if($debug);

	@t_files = `$h_lib_config{find} $directory -name "$old_file"`; #voir pour le passe en perl2find
	for( @t_files ) {
	    chomp $_;
	    $temp_new_file = $new_file;

	    if( $temp_new_file =~ /\*(.*)$/ ) { #match l'extension dans le pattern
		$extension = $1 if( defined $1 );
		($temp_new_file = $_) =~ s/\.[\w]+$/$extension/; #remplace l'extension du fichier par celuis du pattern
	    }

	    $h_files->{$temp_new_file} .= "$_ ";
	}
    }
}


=head3 string2hash

    	Title        : string2hash
	Usage        : string2hash( $string, $h_pattern )
	Prerequisite : none
	Fonction     : Recupere la ligne de paramettre outinput et la transforme en hash.
                       Structure de la ligne : cle1=valeur1[,cleN=valeurN]
	Returns      : none
	Args         : $string : paramettre outinput
                       $h_pattern : reference au hash contenant les patterns outinput
        Globals      : none

=cut

#voir si getopt ne le gere pas.
sub string2hash() {
    &error('[MigaleBiomaj.pm] string2hash : two arguments requiered') if( scalar(@_) < 2 );

    my ( $string, $hash_string, $key, $value, $h_pattern );

    $string = shift;
    $h_pattern = shift;

    foreach $hash_string (split /\,/, $string) {
	( $key, $value ) = split /=/, $hash_string;
	&debug('[MigaleBiomaj.pm] string2hash ($key,$value): '.$key.'='.$value) if( $debug );

	$h_pattern->{$key} = $value;
    }
    &debug('[MigaleBiomaj.pm] string2hash (%h_pattern) : '.Dumper(%$h_pattern) ) if( $debug );
}

=head2 Gestion du mode d execution des commandes

=head3 execution_factory

    	Title        : execution_factory
	Usage        : execution_factory( $h_jobs )
	Prerequisite : none
	Fonction     : Gere le mode d execution en fonction des parametres dans le hash.
	Returns      : Code retour du job ou du cluster
	Args         : $h_jobs : reference de hash contenant les informations du processus.
        Globals      : none

=cut

sub execution_factory() {
    &error('[MigaleBiomaj.pm] execution_factory : one arguments requiered') if( scalar(@_) < 1 );

    my ( $h_jobs );
    my ( $error, $job_return, $diagnosis, $jobid, $jt, $cmdline );

    $h_jobs = shift;

  SWITCH:for( $h_jobs->{batch_system} ) {

      /^local$/i && do {
	  for( @{$h_jobs->{argv}} ) { 
	      $cmdline .= " $_" ;
	  }
	  &info( $h_jobs->{remote_command} . $cmdline );
	  
	  $job_return = system( $h_jobs->{remote_command} . $cmdline );
	  die "Error - $h_jobs->{remote_command} returned non-zero exit code : $job_return \n $!" if( $job_return );

	  return $job_return;
	  last;
      };

      /^drmaa$/i && do {
	  $jt = &drmaa_job_template($h_jobs);
	  
	  &info('Run jobs '.$h_jobs->{'job_name'});
	 
	  for( @{$h_jobs->{argv}} ) { 
	      $cmdline .= " $_";
	  }
	  &info( $h_jobs->{remote_command} . $cmdline );
	  
	  ( $error, $job_return, $diagnosis ) = drmaa_run_job( $jt );
	  die drmaa_strerror( $error ) . "\n" . $diagnosis if( $error );
	  
	  return $job_return;
	  last;
      };

      /^debug$/i && do {
	  for( @{$h_jobs->{argv}} ) { 
	      $cmdline .= " $_" ;
	  }
	  &info( $h_jobs->{remote_command} . $cmdline );

	  last;
      };
      &error('Batch system unknown');      
  }
}

=head2 Gestion des cluster via l API DRMAAc

=head3 drmaa_job_template

    	Title        : drmaa_job_template
	Usage        : drmaa_job_template( $h_jobs )
	Prerequisite : none
	Fonction     : Initialise les variables pour un job dans DRMAAc
	Returns      : Retourne le template du job
	Args         : $h_jobs : reference de hash contenant les informations du processus.
        Globals      : none

=cut

sub drmaa_job_template() {
    &error('[MigaleBiomaj.pm] drmaa_job_template : one arguments requiered') if( scalar(@_) < 1 );

no strict;

    my ( $h_jobs );
    my ( $error, $diagnosis, $jt );
    my ( @email, @argv, @env );
    
    $h_jobs = shift;
#transforme en array une chaine de caractere car DRMAA ne prend que des references de tableau
    $h_jobs->{adminmail} = [$h_jobs->{adminmail}] if( !($h_jobs->{adminmail} =~ m/ARRAY/) );
    @env = split ',', $h_jobs->{env} if( $h_jobs->{env} );

#initiation du template pour le job
    ( $error, $jt, $diagnosis ) = drmaa_allocate_job_template();
    die 'Error - drmaa_allocate_job_template - '.drmaa_strerror( $error ) . "\n" . $diagnosis                    if( $error );
#genere le template du job avec les infos du hash    
    ( $error, $diagnosis ) = drmaa_set_attribute( $jt, $DRMAA_REMOTE_COMMAND, $h_jobs->{remote_command} );
    die 'Error - drmaa_set_attribute DRMAA_REMOTE_COMMAND - '.drmaa_strerror( $error ) . "\n" . $diagnosis       if( $error );
    ( $error, $diagnosis ) = drmaa_set_attribute( $jt, $DRMAA_WD, $h_jobs->{index_dir} );
    die 'Error - drmaa_set_attribute DRMAA_WD - '.drmaa_strerror( $error ) . "\n" . $diagnosis                   if( $error );
    ( $error, $diagnosis ) = drmaa_set_attribute( $jt, $DRMAA_JOB_NAME, $h_jobs->{job_name} );
    die 'Error - drmaa_set_attribute DRMAA_JOB_NAME - '.drmaa_strerror( $error ) . "\n" . $diagnosis             if( $error );
    ( $error, $diagnosis ) = drmaa_set_attribute( $jt, $DRMAA_NATIVE_SPECIFICATION, $h_jobs->{cluster_option} );
    die 'Error - drmaa_set_attribute DRMAA_NATIVE_SPECIFICATION - '.drmaa_strerror( $error ) . "\n" . $diagnosis if( $error );
     ( $error, $diagnosis ) = drmaa_set_attribute( $jt, $DRMAA_BLOCK_EMAIL, $h_jobs->{block_email} );
    die 'Error - drmaa_set_attribute DRMAA_BLOCK_EMAIL - '.drmaa_strerror( $error ) . "\n" . $diagnosis          if( $error );
     ( $error, $diagnosis ) = drmaa_set_attribute( $jt, $DRMAA_OUTPUT_PATH, $h_jobs->{host}.$h_jobs->{log_dir} );
    die 'Error - drmaa_set_attribute DRMAA_OUTPUT_PATH - '.drmaa_strerror( $error ) . "\n" . $diagnosis          if( $error );
     ( $error, $diagnosis ) = drmaa_set_attribute( $jt, $DRMAA_ERROR_PATH, $h_jobs->{host}.$h_jobs->{log_dir} );
    die 'Error - drmaa_set_attribute DRMAA_ERROR_PATH - '.drmaa_strerror( $error ) . "\n" . $diagnosis           if( $error );
    
     ( $error, $diagnosis ) = drmaa_set_vector_attribute( $jt, $DRMAA_V_EMAIL, $h_jobs->{adminmail} );
    die 'Error - drmaa_set_vector_attribute DRMAA_V_EMAIL - '.drmaa_strerror( $error ) . "\n" . $diagnosis       if( $error );
    ( $error, $diagnosis ) = drmaa_set_vector_attribute( $jt, $DRMAA_V_ARGV, $h_jobs->{argv}  );
    die 'Error - drmaa_set_vector_attribute DRMAA_V_ARGV - '.drmaa_strerror( $error ) . "\n" . $diagnosis        if( $error );
    ( $error, $diagnosis ) = drmaa_set_vector_attribute( $jt, $DRMAA_V_ENV, \@env );
    die 'Error - drmaa_set_vector_attribute DRMAA_V_ENV - '.drmaa_strerror( $error ) . "\n" . $diagnosis         if( $error );

    return $jt;
}

=head3 drmaa_initiation

    	Title        : drmaa_initiation
	Usage        : drmaa_initiation
	Prerequisite : none
	Fonction     : Initialise DRMAAc.
	Returns      : none
	Args         : none
        Globals      : none

=cut

sub drmaa_initiation() {
    my ( $error, $diagnosis );

    &info('Initiation of DRMAA');
    ( $error, $diagnosis ) = drmaa_init( undef );
    &warning('Warnning - drmaa_init failed - '.drmaa_strerror( $error ) . "\n" . $diagnosis) if( $error );  
}

=head3 drmaa_synchronization

    	Title        : drmaa_synchronization
	Usage        : drmaa_synchronization($job_constant)
	Prerequisite : none
	Fonction     : Permet d attendre les jobs avant de continuer le script.
	Returns      : none
	Args         : $job_constant : reference d un tableau contenant les id des jobs concernes par la synchronisation
        Globals      : none

=cut

sub drmaa_synchronization() {
    &error('[MigaleBiomaj.pm] drmaa_synchronization : one arguments requiered') if( scalar(@_) < 1 );

no strict;

    my ( $error,$diagnosis, $job_id_out, $stat, $rusage,$remoteps,$exit_status );
    my ( @job_constant );

    my $job_constant = shift;

    &info('Synchronize');
    for( @$job_constant ) {
	( $error, $job_id_out, $stat, $rusage, $diagnosis ) = drmaa_wait( $_, $DRMAA_TIMEOUT_WAIT_FOREVER );
	die 'Error - drmaa_wait - '. drmaa_strerror( $error ) . "\n" . $diagnosis if( $error );
	
	( $error, $exit_status, $diagnosis ) = drmaa_wexitstatus( $stat );
	die 'Error - drmaa_wexitstatus - '.drmaa_strerror( $error ) . "\n" . $diagnosis if( $error );
	&error("Job $job_id_out returned a non-zero exit code : $exit_status") if( $exit_status );

	( $error, $exited, $diagnosis ) = drmaa_wifexited( $stat );
	die 'Error - drmaa_wexitstatus - '.drmaa_strerror( $error ) . "\n" . $diagnosis if( $error );
	&error("Scheduler return error for job $job_id_out") if( !$exited );
    }

    ( $error, $diagnosis ) = drmaa_exit();
    die 'Error - drmaa_exit - '.drmaa_strerror( $error ) . "\n" . $diagnosis if( $error );
}


1;
