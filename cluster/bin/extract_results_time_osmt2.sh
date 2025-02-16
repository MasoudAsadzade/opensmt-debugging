#!/usr/bin/env bash
if [[ $# == 0 ]]; then
    echo "Usage: $0 <result-dir>";
    exit 1;
fi

for file in $1/*.*.out; do
    name=$(echo $file |sed 's,'$1'/\([0-9][0-9]*\)\.\([0-9][0-9]*\)\.out,\1,g');
    num=$(echo $file |sed 's,'$1'/\([0-9][0-9]*\)\.\([0-9][0-9]*\)\.out,\2,g');
    inst=$(echo $(head -1 $file) |sed 's/.smt2.bz2$//g');
    if (grep '^sat' $file > /dev/null); then
        result=sat
    elif (grep '^unsat' $file > /dev/null); then
        result=unsat
    else
        result=indet
    fi
    dn=$(dirname $file)
    tf=${dn}/${name}.osmt.${num}.time
    tm=$(sed -n 's/.* wall: \(.*\) CPU: .*/\1/p' $tf)
# [hyvaeria@cub satcomp]$ less
# results-osmt/osmt.289-sat-6x20.smt2.bz2.sh.osmt.0.time
# user: 0.15 system: 0.01 wall: 0.17 CPU: 98%CPU
# [hyvaeria@cub satcomp]$
    echo $inst $result $tm;
done

