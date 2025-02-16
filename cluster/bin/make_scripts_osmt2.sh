#!/bin/bash


if [[ $# -ne 5 ]]; then
    echo "Usage: $0 <osmt> <script-dir> <output-dir> <config> <benchmark path>";
    exit 1;
fi

osmt=$1; shift
scripts=$1; shift
results=`readlink -e $1`; shift
config=$1; shift
bmpath=$1; shift

i=0
# How many processes to run in the node
ncpus=10
# Timeout (this is probably in CPU time so if you run multithreaded,
# mutiply the number by the number of threads)
timeout=1000

files=()
for file in $(find $bmpath -name '*.smt2.bz2'); do
    files+=( ${file} )
done

set -- "${files[@]}"

r=0
while (( $# )); do
    scriptfile=$(printf "${scripts}/%04d.sh" ${r})
    outfilebase=$(printf "${results}/%04d" ${r})
    ex=$1;
    echo "generating $scriptfile"
    cat << __EOF__ > $scriptfile
#!/bin/bash
## Generated by $0
## From $ex
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --mem=0
#SBATCH --output=$outfilebase.out
#SBATCH --error=$outfilebase.err

osmt_time=$outfilebase.osmt
output=$outfilebase

config=${config}
script=${osmt}
#script=/home/hyvaeria/bin/run-dumper.sh
__EOF__

    for ((i=0; i < $ncpus; i++)); do
        if [[ $# == 0 ]]; then
            break;
        fi
        ex=$1; shift
        ex_id=$(echo $ex |sed 's!^'$bmpath'[/]*!!g')
        ex_printable=$(echo $ex_id |tr '/' '_')
        cat << __EOF__ >> $scriptfile
 (
  echo $ex_id;
  TMPDIR=\$(mktemp -d)
  trap "rm -rf \$TMPDIR" EXIT
  inp=\$TMPDIR/\$(basename \${script})-`basename $ex_printable .bz2`;
  bunzip2 -c $ex > \${inp};
  sh -c "ulimit -St ${timeout};
  ulimit -Sv 4000000;
  /usr/bin/time -o \${osmt_time}.${i}.time -f 'user: %U system: %S wall: %e CPU: %PCPU' \$script \$config \$inp" || true;
 ) > \$output.${i}.out 2> \$output.${i}.err &
__EOF__
    done
    echo "wait" >> $scriptfile
    i=$((i+1))
    chmod +x $scriptfile
    r=$((r+1))
done
