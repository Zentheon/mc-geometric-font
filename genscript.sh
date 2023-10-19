#!/bin/bash

# This script generates useable resourcepacks in .zip format.
# Output located in ./generated

# Exit if running under root
if [ "$EUID" = 0 ]
    then
    echo
    echo ":: Please run without root privileges"
    echo
    exit 1
fi


# Check deps
hash inkscape 2>/dev/null || {
    echo >&2 "Inkscape is not installed."
    EXIT=1
}
hash 7z 2>/dev/null || {
    echo >&2 "7z (7-Zip, p7zip) is not installed."
    EXIT=1
}
hash sed 2>/dev/null || {
    echo >&2 "sed is not installed."
    EXIT=1
}
[ "$EXIT" = "1" ] && {
    echo
    echo ":: One or more dependencies are missing. Aborting."
    echo
    exit 1
}

# Check if generated packs already exist
[ -d "./generated" ] && {
    while [ "$INPUT" != "y" ]
    do
        echo
        echo -e "Generated packs already exist. Regenerate?"
        read -s -n 1 INPUT
        [ "$INPUT" = "n" ] && exit 1
        [ "$INPUT" = "y" ] && \rm -r ./generated
    done

}

# Pack version
PACKVER=v1.2

# GUI scale DPIs
GUI=(0 24 48 72 96 120 144 168 192)

# Initial setup
mkdir ./tmp
for SCALE in 2 3 4 5 6 7 8
do
    echo "Generating for scale $SCALE..."
    cp -r ./src ./tmp/$SCALE
    for file in ./tmp/$SCALE/*/*/*/*/*.svg
    do
        inkscape "$file" -d ${GUI[$SCALE]} --export-filename "${file%svg}png"
    done
done

# Delete temp SVGs
rm ./tmp/*/*/*/*/*/*.svg

# Pack Zipping
echo "Zipping packs..."
mkdir ./generated
for SCALE in 2 3 4 5 6 7 8
do
    sed -i -e "s/-SCALE/$SCALE/g" ./tmp/$SCALE/pack.mcmeta
    cd ./generated
    7z a "GeoFont Legacy $PACKVER GUI Scale $SCALE.zip" \
        ../tmp/$SCALE/assets ../tmp/$SCALE/LICENSE.md ../tmp/$SCALE/pack.mcmeta ../tmp/$SCALE/pack.png \
        > /dev/null 2>&1
    cd ..
done

# Clean up and send finished message
\rm -r ./tmp
echo
echo ":: Done. Output availible in ./generated"
echo
