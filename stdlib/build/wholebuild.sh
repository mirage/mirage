#!/bin/bash
# experimental (and non-functioning whole build script)

OUT=$1
if [ -z "$OUT" ]; then
  echo "Usage: $0 <output-name>"
  exit 1
fi
OUTMLI=$OUT.mli
OUTML=$OUT.ml

function toupper {
   local MOD=$(echo $2 | sed -e "s/\.$1\$//g")
   local FMOD=$(echo $MOD | cut -b1 | tr 'a-z' 'A-Z')
   local RMOD=$(echo $MOD | cut -b2-)
   MODNAME="$FMOD$RMOD"
}
  
MLI=$(ocamldsort -mli *.mli)
ML=$(ocamldsort *.ml)

for i in $MLI; do
  toupper "mli" $i
  echo module $MODNAME : sig >> $OUTMLI
  cat $i >> $OUTMLI
  echo end >> $OUTMLI
done

for i in $ML; do
  toupper "ml" $i
  echo module $MODNAME = struct >> $OUTML
  cat $i >> $OUTML
  echo end >> $OUTML
done
