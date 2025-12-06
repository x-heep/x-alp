# Copy generated waves to common directory
# Usage: copy-waves.sh wave_file [wave_file] ...

ROOT_DIR=$(git rev-parse --show-toplevel)
mkdir -p $ROOT_DIR/logs
for file in "$@"; do
    [ ! -f $file ] && continue
    FILE_EXT="${file##*.}"
    rm -f $ROOT_DIR/logs/waveform.$FILE_EXT
    ln -sr $file $ROOT_DIR/logs/waveform.$FILE_EXT
done

# Additionally copy separate wave files, if any
FILE_LIST=$(dirname $1)/*.vcd
for file in $FILE_LIST; do
    rm -f $ROOT_DIR/logs/$(basename $file)
    ln -sr $file $ROOT_DIR/logs/
done

exit 0
