#!/usr/bin/perl
# Author : Genopole Toulouse - Yoann.Beausse@toulouse.inra.fr
# Version : 0.8
# Date : 01/03/2007
#
#-------------------------------------------------------------------------------
# PROGRAMME     : sendMailTLSE.pl
# VERSION       : 0.8
# DATE          : 01/03/2007
# COMMENTAIRES  : 
# Au 01/03/2007 : Ce script envoye des mails dans le cadre des pre et post process de Biomaj.
#
# PREREQUIS     : Toutes les commandes system dans ce script sont definis dans le fichier unix_command_system.cfg
#                 Pour le moment, ce fichier doit exister dans $BIOMAJ_ROOT/scripts/ avec le path des commandes unix ci-dessous pour la bonne execution de ce script :
#                 UNIX_MAIL
#
# AIDE         : sendMailTLSE.pl --help
#
#
# VARIABLES
#  D'ENVIRONNEMENT :  Donnees par Biomaj : BIOMAJ_ROOT PP_WARNING PP_END dbname datadir dirversion remoterelease offlinedir remotedir dirversion noextract localfiles remotefiles
#
# UTILISATION   : --to (-t) 'toto@titi.fr'
#                 --subject (-s) Sujet du message
#                 --message (-m) Corps de message
#
#                 Si --to n'est pas renseigne, on utilise $ENV{BIOMAJ_ADMIN_MAIL}. Si toujours vide, exit (0). Ici le code de retour sur erreur est 0 pour ne pas faire arreter Biomaj sur une erreur d'envoi de mail.
#                 Si --subject n'est pas renseigne, le sujet par defaut est : "No subject !!!"
#                 Si --message n'est pas renseigne, seul un warning est emis et le mail est envoye.
#
#                 Dans --subject et --message, on peut utiliser certaine variable qui seront interpretees par sendMailTLSE.pl
#                 - db.name data.dir dir.version offline.dir remote.dir dir.version no.extract local.files remote.files
#                     ---> reprend les valeurs de ces meme variables dans le fichier bank.properties
#                 - remote.release ---> Variable de Biomaj calcule dynamiquement (N'est disponible que pour un POST process)
#                 - removed.release ---> Variable de Biomaj calcule dynamiquement (N'est disponible que pour un REMOVE process)
#                 - local.time ---> date et heure (Thu Mar  1 15:05:48 2007)
#
# How to call it in a bank.properties file ? (ex alu.properties)
# db.pre.process=PRE1

# PRE1=premail

# premail.name=sendMail
# premail.exe=sendMailTLSE.pl
# premail.args=-s '[NCBI Blast - db.name] Start Biomaj session' -m 'local.time'
# premail.desc=mail
# premail.type=info

#-------------------------------------------------------------------------------

=head1 NAME

sendMailTLSE.pl - Envoie de mail

=head1 SYNOPSIS

sendMailTLSE.pl [--to adresse@mail] [--subject "subject"] [--message "msg"] [--help]

=head1 Description

Ce script fait partie des PostProcess de BioMaJ.
Il permet d'envoyer un mail a l'administrateur de Biomaj (par defaut) ou a tout autre adresses.
Ce script peut substituer certaines variables de BioMaJ par leur valeur : 

    - db.nanme
    - data.dir
    - dir.version
    - offline.dir
    - remote.release
    - removed.release
    - remote.dir
    - remote.files
    - local.files
    - no.extract

 et - local.time qui est remplace par la date et l'heure selon de format "ddd mmm jj hh:mm:ss aaaa"
 d:Jour de la semaine, m:mois, j:numero du jour, h:heure, m:minute, s:seconde, a:annee

=head1 VERSION

Version 0.9
March 2007

=head1 COPYRIGHT

This program is distributed under the CeCILL License. (http://www.cecill.info)

=head1 ARGUMENTS

B<--to (-t) adresse@mail>

	Adresse mail du destinataire.
	Un mail sera toujours envoye a l'adresse precissee par la variable 'mail.admin' dans global.properties (BioMaJ)
		default = $ENV{mailadmin}

B<--subject (-s) 'subject'>

	Sujet du mail. 
		default = "No subject !!!"

B<--message (-m) 'message'>

	Message du mail
		default = ""

B<--help (-h)>

=head1 AUTHOR

 Yoann Beausse <Yoann.Beausse@toulouse.inra.fr>
 Plateforme Bioinformatique - Genopole Midi-Pyrenees Toulouse

=cut



use strict;
use Getopt::Long;
use lib ("$ENV{BIOMAJ_ROOT}/conf/process/.");
use ProcessBiomajLib;

my %H_CMD;
my ($TO,$SUBJECT,$MESSAGE,$HELP)=("","","");

my $result = GetOptions ( "to=s"      => \$TO,
						  "subject=s" => \$SUBJECT,
						  "message=s" => \$MESSAGE,
						  "help"      => \$HELP,
						  );
						  
MAIN:
{
	&Usage() if ($HELP);	
	
	&InitGlobalVar();
	$SUBJECT = &SubstituteFlag($SUBJECT);
	$MESSAGE = &SubstituteFlag($MESSAGE);
	
	my $file_msg = "/tmp/bmaj.msg";
	open(MSG,">$file_msg");
	print MSG $MESSAGE;
	close(MSG);
	
	my $cmd = "$H_CMD{UNIX_MAIL} -s \"$SUBJECT\" $TO < $file_msg";
	`$cmd`;

	unlink($file_msg);
}

=head1 Routines

=head2 procedure SubstituteFlag

	Title        : SubstituteFlag
	Usage        : SubstituteFlag($string)
	Prerequisite : none
	Fonction     : Substitue les flag par leur valeur.
	Returns      : $string
	Args         : $string : string a traiter
	Globals      : none

=cut
sub SubstituteFlag
{
	my $string = shift;
	
	$string =~ s/db.name/$ENV{dbname}/gm                if ( $ENV{dbname} ne "" );
	$string =~ s/remote.release/$ENV{remoterelease}/gm  if ( $ENV{remoterelease} ne "" );
	$string =~ s/removed.release/$ENV{removedrelease}/gm  if ( $ENV{remoterelease} ne "" );
	$string =~ s/data.dir/$ENV{datadir}/gm              if ( $ENV{datadir} ne "" );
	$string =~ s/offline.dir/$ENV{offlinedir}/gm        if ( $ENV{offlinedir} ne "" );
	$string =~ s/remote.dir/$ENV{remotedir}/gm          if ( $ENV{remotedir} ne "" );
	$string =~ s/dir.version/$ENV{dirversion}/gm        if ( $ENV{dirversion} ne "" );
	$string =~ s/no.extract/$ENV{noextract}/gm          if ( $ENV{noextract} ne "" );
	$string =~ s/local.files/$ENV{localfiles}/gm        if ( $ENV{localfiles} ne "" );
	$string =~ s/remote.files/$ENV{remotefiles}/gm      if ( $ENV{remotefiles} ne "" );


	my $time = scalar localtime(time);
	$string =~ s/local.time/$time/g;
	return $string;
}

=head2 procedure InitGlobalVar

	Title        : InitGlobalVar
	Usage        : InitGlobalVar()
	Prerequisite : none
	Fonction     : Initialisation des variables.
	Returns      : none
	Args         : none
	Globals      : 

=cut
sub InitGlobalVar
{
	&ProcessBiomajLib::readCfgFile(\%H_CMD);
	
	if ( exists($ENV{mailadmin}) )
	{
		if ( $TO !~ /$ENV{mailadmin}/ )
		{
			$TO .= " " if ($TO ne "");
			$TO .= "$ENV{mailadmin}"
		}
	}

	$TO = "\"$TO\"";
	
	if ( $TO !~ /\S+@\S+\.\S+/ )
	{
		&Warning("Address not valid : $TO");
		&Warning("Message not send");
		exit(0);
	}
	
	&Warning("Message is empty") if ( $MESSAGE eq "" );
	
	if ( $SUBJECT eq "")
	{	
		$SUBJECT = "No subject !!!";
		&Warning("Subject is empty. Default subject is : $SUBJECT");
	}
	return;
}

=head2 procedure Usage

	Title        : Usage
	Usage        : Usage($msg)
	Prerequisite : none
	Fonction     : Affiche $msg + l'usage du script + exit(1)
	Returns      : none
	Args         : $msg : message precisant l'erreur
	Globals      : none

=cut
sub Usage()
{
	
	my $message = shift;
	
print STDERR "$message\n" if ( defined($message) && $message ne "" );
	
print STDOUT <<END

./sendMailTLSE.pl

Arguments : 
   optional :
        --to      (-t)       : adresse mail du destinataire. Default : \$ENV{mail.admin}
        --subject (-s)       : sujet du message.             Default : "No subject !!!"
        --message (-m)       : Corps du message.             Default : ""
        --help    (-h)       : This mesage
END
;
	exit(-1);
}

