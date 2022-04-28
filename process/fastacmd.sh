# ! /bin/bash
#
# -d  Database [String]  Optional
#    default = nr
#  -p  Type of file
#         G - guess mode (look for protein, then nucleotide)
#         T - protein
#         F - nucleotide [String]  Optional
#    default = G
#  -s  Comma-delimited search string(s).
#      GIs, accessions, loci, or fullSeq-id strings may be used,
#      e.g. 555, AC147927, 'gnl|dbname|tag' [String]  Optional
#  -i  Input file with GIs/accessions/loci for batch
#      retrieval [String]  Optional
#  -a  Retrieve duplicate accessions [T/F]  Optional
#    default = F
#  -l  Line length for sequence [Integer]  Optional
#    default = 80
#  -t  Definition line should contain target gi only [T/F]  Optional
#    default = F
#  -o  Output file [File Out]  Optional
#    default = stdout
#  -c  Use Ctrl-A's as non-redundant defline separator [T/F]  Optional
#    default = F
#  -D  Dump the entire database as (default is not to dump anything):
#      1 FASTA
#      2 Gi list
#      3 Accession.version list
# [Integer]  Optional
#    default = 0
#    range from 0 to 3
#  -L  Range of sequence to extract (Format: start,stop)
#      0 in 'start' refers to the beginning of the sequence
#      0 in 'stop' refers to the end of the sequence [String]  Optional
#    default = 0,0
#  -S  Strand on subsequence (nucleotide only): 1 is top, 2 is bottom [Integer]
#    default = 1
#  -T  Print taxonomic information for requested sequence(s) [T/F]
#    default = F
#  -I  Print database information only (overrides all other options) [T/F]
#    default = F
#  -P  Retrieve sequences with this PIG [Integer]  Optional




#GLOBAL DEF
#----------

FASTACMD=/local/miniconda3/envs/blast-2.9.0/bin/blastdbcmd;

# MAIN
#-----------

if (test $# -ne 4) then
        # example: 'refseq_protein' 'flat' 'fasta/All' 'all.fasta'
        echo "arguments:" 1>&2
        echo "1: bank name"
        echo "2: source directory (index blast)"
        echo "3: working directory" 1>&2
        echo "4: outputfile" 1>&2
        echo `$FASTACMD --help`;
        exit -1
fi

srcdir=$datadir/$dirversion/future_release/$2;

#cd $workdir;

if ( test $? -ne 0 ) then
        echo "$srcdir do not exist !" 1>&2 ;
        exit 1;
fi

workdir=$datadir/$dirversion/future_release/$3;

rm -rf $workdir;
mkdir -p $workdir ;

if ( test $? -ne 0 ) then
        echo "Cannot create $workdir." 1>&2 ;
        exit 1;
fi

cd $workdir
#Fix Ticket#: 2009051210000013, add -c option - 30/06/09 OSALLOU
$FASTACMD -ctrl_a -entry all -db $srcdir/$1 -out $workdir/$4;

if ( test $? -ne 0 ) then
        echo "Error with :$FASTACMD -ctrl_a -entry all -db $srcdir/$1 -out $workdir/$4" 1>&2 ;
        exit 1;
fi


