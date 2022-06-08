#!/bin/bash


if [[ $# -lt 5 ]]; then
    echo "Usage: $0 <smts> <script-dir> <output-dir> <config> <example1> [<example2> [ ... ] ]";
    exit 1;
fi

smts_server=$1; shift
lemma_sharing=$1; shift
script_dir=$1; shift
#work under linux
out_dir=`readlink -e $1`; shift

#work under mac
#out_dir=$(cd $(basename $1); pwd) shift

config=$1; shift

counter=0

# How many SMTS to run in the node (three smts_server on different ports, each 3 solver and one lemmas server)
# Total process = 3 smts_server + 9 solver_client + 3 lemma_server
n_smts=3

# SMTS Timeout
timeout=1000

# Starting port
port=3000
while [[ $# > 0 ]]; do
    ex=$1;
    bname=`basename $ex`
    script_name=`printf "smts.%s.sh" ${bname}`
    echo $script_name
    cat << __EOF__ > $script_dir/$script_name
#!/bin/bash
## Generated by $0
## From $ex
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --mem=0
#SBATCH --output=$out_dir/$script_name.out
#SBATCH --error=$out_dir/$script_name.err

smts_time=$out_dir/$script_name.smts
output=$out_dir/$script_name

config=${config}
script=${smts_server}

__EOF__

    for ((i=0; i < $n_smts; i++)); do
        if [[ $# == 0 ]]; then
            break;
        fi
        ex=$1; shift
        cat << __EOF__ >> $script_dir/$script_name
 (
  echo $ex;
  inp=/tmp/\$(basename \${script})-`basename $ex .bz2`;
  bunzip2 -c $ex > \${inp};
  sh -c "/usr/bin/time -o \${smts_time}.${i}.time -f 'user: %U system: %S wall: %e CPU: %PCPU' python3 \$script $lemma_sharing -o3 -p $((port+i)) -fp \$inp" || true; rm \${inp};
 ) > \$output.${i}.out 2> \$output.${i}.err;
 out_path=\$output.${i}
 grep '^;' \$out_path.out > /dev/null && (cat \$out_path.out >> \$out_path.err; echo $ex'\n'error  > \$out_path.out) &
__EOF__
    done
    echo "wait" >> $script_dir/$script_name
    counter=$((counter+1))
    chmod +x $script_dir/$script_name
done