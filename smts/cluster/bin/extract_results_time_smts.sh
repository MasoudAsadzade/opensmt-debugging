#!/usr/bin/env bash
if [[ $# != 2 ]]; then
    echo "Usage: $0 <result-dir> <project osmt|smts>";
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
    tf=${dn}/${name}.$2.${num}.time
    tm=$(sed -n 's/.* wall: \(.*\) CPU: .*/\1/p' $tf)
    echo $inst $result $tm;
done