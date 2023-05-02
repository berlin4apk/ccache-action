#!/usr/bin/env bash

set -xv

# docker run --rm -it ubuntu:22.04
# apt update && apt install --yes curl build-essential nvi git shellcheck ash apt-file file busybox
# export CI="true"
# rm -fr /usr/local/lib/sccache /usr/lib/sccache /usr/local/bin/*  /update-sccache-symlinks.sh
# git clone https://github.com/berlin4apk/ccache-action.git --branch dev
# git -C ccache-action pull ; cp ccache-action/src/update-sccache-symlinks.sh /
####
# rm -fr /usr/local/lib/sccache /usr/lib/sccache /usr/local/bin/* ; git -C ccache-action pull ; cp ccache-action/src/update-sccache-symlinks.sh /
# bash ./update-sccache-symlinks.sh
# printf '%s\n' "$PATH" | /bin/sed -e 's@:'$SCCACHE_WRAPPER_BINDIR':@@g' -e 's@'$SCCACHE_WRAPPER_BINDIR':@@g' -e 's@:'$SCCACHE_WRAPPER_BINDIR'@@g'
# /usr/local/lib/sccache/gcc 2>&1 | grep --color=always -E "/usr/local/lib/sccache|delete any instances|$"

_has_command() {
  # well, this is exactly `for cmd in "$@"; do`
  for cmd do
    command -v "$cmd" >/dev/null 2>&1 || return 1
  done
}
     _has_command sudo && {
#    sudo -n echo 2>/dev/null && SudoVAR="-n $SudoVAR" || SudoVAR="$SudoVAR"
    sudo -n echo 2>/dev/null && SudoVAR="-n $SudoVAR"
  }
     _has_command sudo && {
#    sudo -E echo 2>/dev/null && SudoE="sudo -E $SudoVAR" || SudoVAR="$SudoVAR"
    sudo -E echo 2>/dev/null && SudoE="sudo -E $SudoVAR"
  }
     _has_command sudo && {
    sudo echo 2>/dev/null && Sudo="sudo $SudoVAR" || Sudo=""
  }

export "$(dpkg-architecture)"
export -p | grep -i deb

### export DEBUG=1

# PN=$(dirname "$0")

[ -d /usr/local/bin/ ] || $Sudo mkdir -p /usr/local/bin/
[ -d /usr/local/lib/sccache/ ] || $Sudo mkdir -p /usr/local/lib/sccache/
# [ -e /usr/local/bin/sccache ] || $Sudo touch /usr/local/bin/ccache
# $Sudo "$PN"/update-ccache-symlinks.pl


if [ "$CI" != "true" ]; then
	echo runing not in CI, no apt install
else
_has_command sccache || {
	echo runing in CI, missing sccache, no install sccache to /usr/local/bin/
	###curl -L https://github.com/ccache/ccache/releases/download/v4.8/ccache-4.8-linux-x86_64.tar.xz | $Sudo tar -xJvf- --strip-components=1 -C /usr/local/bin/
[[ -e sccache-v0.4.2-x86_64-unknown-linux-musl.tar.gz ]] || curl -LORJ https://github.com/mozilla/sccache/releases/download/v0.4.2/sccache-v0.4.2-x86_64-unknown-linux-musl.tar.gz
[[ -e sccache-v0.4.2-x86_64-unknown-linux-musl.tar.gz.sha256 ]] || curl -LORJ https://github.com/mozilla/sccache/releases/download/v0.4.2/sccache-v0.4.2-x86_64-unknown-linux-musl.tar.gz.sha256
	echo "4cf08e75c2b311424eed2768dada6056569be4ac1d4cbed980e471bf1452d12c *sccache-v0.4.2-x86_64-unknown-linux-musl.tar.gz" | sha256sum -c -
	$Sudo tar -xzvf sccache-v0.4.2-x86_64-unknown-linux-musl.tar.gz --strip-components=1 -C /usr/local/bin/
 }
fi



          # By default, sccache will fail your build if it fails to successfully communicate with its associated server. To have sccache instead gracefully failover to the local compiler without stopping, set the environment variable SCCACHE_IGNORE_SERVER_IO_ERROR=1.
          echo build-with-SCCACHE
          # see https://github.com/mozilla/sccache/issues/1155#issuecomment-1097557677
[ -d /usr/local/lib/sccache/ ] || $Sudo mkdir -p /usr/local/lib/sccache/
cat <<EOF1 | $SudoE tee /usr/local/lib/sccache/sccache-wrapper2
#!/usr/bin/env bash
SCCACHE_BIN="\$(command -v sccache || echo sccache )"
cd "\$(dirname "\$0")" || exit 2
for COMPILER in "c++" "c89" "c99" "cc" "clang" "clang++" "cpp" "g++" "gcc" "rustc" "x86_64-pc-linux-gnu-c++" "x86_64-pc-linux-gnu-cc" "x86_64-pc-linux-gnu-g++" "x86_64-pc-linux-gnu-gcc" "arm-none-eabi-c++" "arm-none-eabi-cc" "arm-none-eabi-g++" "arm-none-eabi-gcc" "aarch64-linux-gnu-c++" "aarch64-linux-gnu-cc" "aarch64-linux-gnu-g++" "aarch64-linux-gnu-gcc" "arm-none-eabi-c++" "arm-none-eabi-cc" "arm-none-eabi-g++" "arm-none-eabi-gcc"; do
cat > "./\${COMPILER}" <<-EOF
#!/bin/bash
[ "$DEBUG" != "" ] && set -vx
SCCACHE_WRAPPER_BINDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)  # Intentionally don't resolve symlinks
# SCCACHE_WRAPPER_BINDIR2="\$(dirname \${BASH_SOURCE[0]})"  # Intentionally don't resolve symlinks
PATH=\${PATH//":\$SCCACHE_WRAPPER_BINDIR:"/":"} # delete any instances in the middle
[ "$DEBUG" != "" ] && echo "delete any instance at the beginning"
PATH=\${PATH/#"\$SCCACHE_WRAPPER_BINDIR:"/} # delete any instance at the beginning
[ "$DEBUG" != "" ] && echo "delete any instance in the at the end"
PATH=\${PATH/%":\$SCCACHE_WRAPPER_BINDIR"/} # delete any instance in the at the end
# /usr/bin/sccache \${COMPILER} "\$@"
\${SCCACHE_BIN} \${COMPILER} "$@"
\${SCCACHE_BIN} \${COMPILER} "\\$\\@"
\${SCCACHE_BIN} \${COMPILER} "\$\@"
\${SCCACHE_BIN} \${COMPILER} "\$@"
EOF
chmod 755 "./\${COMPILER}"
done
EOF1

cat <<'Endofmessage' | $SudoE tee /usr/local/lib/sccache/sccache-wrapper
#!/bin/sh
### #!/usr/bin/env bash
_has_command() {
  # well, this is exactly `for cmd in "$@"; do`
  for cmd do
    command -v "$cmd" >/dev/null 2>&1 || return 1
  done
}

[ "$DEBUG" != "" ] && set -vx
SCCACHE_BIN="$(command -v sccache || echo sccache )"
DIRNAME=$(dirname "$0")
#cd "\$(dirname "\$PWD\$0")"
cd "$DIRNAME"
for COMPILER in "c++" "c89" "c99" "cc" "clang" "clang++" "cpp" "g++" "gcc" "rustc" "x86_64-pc-linux-gnu-c++" "x86_64-pc-linux-gnu-cc" "x86_64-pc-linux-gnu-g++" "x86_64-pc-linux-gnu-gcc" "arm-none-eabi-c++" "arm-none-eabi-cc" "arm-none-eabi-g++" "arm-none-eabi-gcc" "aarch64-linux-gnu-c++" "aarch64-linux-gnu-cc" "aarch64-linux-gnu-g++" "aarch64-linux-gnu-gcc" "arm-none-eabi-c++" "arm-none-eabi-cc" "arm-none-eabi-g++" "arm-none-eabi-gcc"; do
#cat > "./\${COMPILER}" <<-EndofScript
set -vx
_has_command bash && {
cat > "./${COMPILER}" <<-EndofScript
#!$(command -v /bin/bash || command -v bash )
### #!/bin/bash
[ "$DEBUG" != "" ] && set -vx
SCCACHE_WRAPPER_BINDIR="\$(dirname \${BASH_SOURCE[0]})"  # Intentionally don't resolve symlinks

# debug
[ "$DEBUG" != "" ] && PATH="\$SCCACHE_WRAPPER_BINDIR:\$PATH:\$SCCACHE_WRAPPER_BINDIR:/usrfoo:\$SCCACHE_WRAPPER_BINDIR"
#PATH="\$SCCACHE_WRAPPER_BINDIR:\$PATH"
#PATH="/usrfoo:\$SCCACHE_WRAPPER_BINDIR:\$PATH"
#PATH="\$PATH/usrfoo:\$SCCACHE_WRAPPER_BINDIR"

### PATH="/usr/local/lib/sccache:\$PATH:/usr/local/lib/sccache:\$PATH:/usr/local/lib/sccache"
#PATH="/usrfoo:/usr/local/lib/sccache:$PATH"
#PATH="$PATH/usrfoo:/usr/local/lib/sccache"

[ "$DEBUG" != "" ] && echo "\$PATH"
[ "$DEBUG" != "" ] && echo "delete any instances in the middle"
PATH=\${PATH//":\$SCCACHE_WRAPPER_BINDIR:"/":"} # delete any instances in the middle
[ "$DEBUG" != "" ] && echo "delete any instance at the beginning"
PATH=\${PATH/#"\$SCCACHE_WRAPPER_BINDIR:"/} # delete any instance at the beginning
[ "$DEBUG" != "" ] && echo "delete any instance in the at the end"
PATH=\${PATH/%":\$SCCACHE_WRAPPER_BINDIR"/} # delete any instance in the at the end
[ "$DEBUG" != "" ] && echo "\$PATH"
# /usr/bin/sccache \${COMPILER} "\$@"
# 1 \${SCCACHE_BIN} \${COMPILER} "$@"
# 2 \${SCCACHE_BIN} \${COMPILER} "\\$\\@"
# 3 \${SCCACHE_BIN} \${COMPILER} "\$\@"
# 4 \${SCCACHE_BIN} \${COMPILER} "\$@"
# 4a ${SCCACHE_BIN} ${COMPILER} "\$@"
${SCCACHE_BIN} ${COMPILER} "\$@"
# 5 \${SCCACHE_BIN} \${COMPILER} '$@'
# 6 \${SCCACHE_BIN} \${COMPILER} '$\@'
# 7 \${SCCACHE_BIN} \${COMPILER} '\$@'
# 8 \${SCCACHE_BIN} \${COMPILER} '\$\@'
# 9 \${SCCACHE_BIN} \${COMPILER} '$@'0
# 10 \${SCCACHE_BIN} \${COMPILER} '$\100'
# 11 \${SCCACHE_BIN} \${COMPILER} '\$@'
# 12 \${SCCACHE_BIN} \${COMPILER} '\$\100'
EndofScript
}
_has_command bash || {
cat > "./${COMPILER}" <<-EndofScript
#!$(command -v /bin/sh || command -v sh )
### #!/bin/sh
[ "$DEBUG" != "" ] && set -vx
SCCACHE_WRAPPER_BINDIR="\$(dirname \$0)"  # Intentionally don't resolve symlinks

# debug
[ "$DEBUG" != "" ] && PATH="\$SCCACHE_WRAPPER_BINDIR:\$PATH:\$SCCACHE_WRAPPER_BINDIR:/usrfoo:\$SCCACHE_WRAPPER_BINDIR"
#PATH="\$SCCACHE_WRAPPER_BINDIR:\$PATH"
#PATH="/usrfoo:\$SCCACHE_WRAPPER_BINDIR:\$PATH"
#PATH="\$PATH/usrfoo:\$SCCACHE_WRAPPER_BINDIR"

### PATH="/usr/local/lib/sccache:\$PATH:/usr/local/lib/sccache:\$PATH:/usr/local/lib/sccache"
#PATH="/usrfoo:/usr/local/lib/sccache:$PATH"
#PATH="$PATH/usrfoo:/usr/local/lib/sccache"

## str=$(printf '%s' "$str" | sed -e 's@/@a@g')
[ "$DEBUG" != "" ] && echo "\$PATH"
[ "$DEBUG" != "" ] && echo "sed: delete any instances in the middle"
[ "$DEBUG" != "" ] && echo "sed: delete any instance at the beginning"
[ "$DEBUG" != "" ] && echo "sed: delete any instance in the at the end"
PATH="\$(printf '%s\n' "\$PATH" | sed -e 's@:'\$SCCACHE_WRAPPER_BINDIR'[/]:@@g' -e 's@'\$SCCACHE_WRAPPER_BINDIR'[/]:@@g' -e 's@:'\$SCCACHE_WRAPPER_BINDIR'[/]@@g' )"
## PATH=\${PATH//":\$SCCACHE_WRAPPER_BINDIR:"/":"} # delete any instances in the middle
## PATH=\${PATH/#"\$SCCACHE_WRAPPER_BINDIR:"/} # delete any instance at the beginning
## PATH=\${PATH/%":\$SCCACHE_WRAPPER_BINDIR"/} # delete any instance in the at the end
[ "$DEBUG" != "" ] && echo "\$PATH"
${SCCACHE_BIN} ${COMPILER} "\$@"
EndofScript
}
chmod 755 ./${COMPILER}
done
Endofmessage


cat <<'Endofmessage' | $SudoE tee /usr/local/lib/sccache/sccache-wrapper-sh
#!/bin/sh
### #!/usr/bin/env bash
_has_command() {
  # well, this is exactly `for cmd in "$@"; do`
  for cmd do
    command -v "$cmd" >/dev/null 2>&1 || return 1
  done
}

[ "$DEBUG" != "" ] && set -vx
SCCACHE_BIN="$(command -v sccache || echo sccache )"
DIRNAME=$(dirname "$0")
#cd "\$(dirname "\$PWD\$0")"
cd "$DIRNAME"
for COMPILER in "c++" "c89" "c99" "cc" "clang" "clang++" "cpp" "g++" "gcc" "rustc" "x86_64-pc-linux-gnu-c++" "x86_64-pc-linux-gnu-cc" "x86_64-pc-linux-gnu-g++" "x86_64-pc-linux-gnu-gcc" "arm-none-eabi-c++" "arm-none-eabi-cc" "arm-none-eabi-g++" "arm-none-eabi-gcc" "aarch64-linux-gnu-c++" "aarch64-linux-gnu-cc" "aarch64-linux-gnu-g++" "aarch64-linux-gnu-gcc" "arm-none-eabi-c++" "arm-none-eabi-cc" "arm-none-eabi-g++" "arm-none-eabi-gcc"; do
#cat > "./\${COMPILER}" <<-EndofScript
[ "$DEBUG" != "" ] && set -vx
_has_command DISABELbash && {
cat > "./${COMPILER}" <<-EndofScript
#!$(command -v /bin/bash || command -v bash )
### #!/bin/bash
[ "$DEBUG" != "" ] && set -vx
SCCACHE_WRAPPER_BINDIR="\$(dirname \${BASH_SOURCE[0]})"  # Intentionally don't resolve symlinks

# debug
[ "$DEBUG" != "" ] && PATH="\$SCCACHE_WRAPPER_BINDIR:\$PATH:\$SCCACHE_WRAPPER_BINDIR:/usrfoo:\$SCCACHE_WRAPPER_BINDIR"
#PATH="\$SCCACHE_WRAPPER_BINDIR:\$PATH"
#PATH="/usrfoo:\$SCCACHE_WRAPPER_BINDIR:\$PATH"
#PATH="\$PATH/usrfoo:\$SCCACHE_WRAPPER_BINDIR"

### PATH="/usr/local/lib/sccache:\$PATH:/usr/local/lib/sccache:\$PATH:/usr/local/lib/sccache"
#PATH="/usrfoo:/usr/local/lib/sccache:$PATH"
#PATH="$PATH/usrfoo:/usr/local/lib/sccache"

[ "$DEBUG" != "" ] && echo "\$PATH"
[ "$DEBUG" != "" ] && echo "delete any instances in the middle"
PATH=\${PATH//":\$SCCACHE_WRAPPER_BINDIR:"/":"} # delete any instances in the middle
[ "$DEBUG" != "" ] && echo "delete any instance at the beginning"
PATH=\${PATH/#"\$SCCACHE_WRAPPER_BINDIR:"/} # delete any instance at the beginning
[ "$DEBUG" != "" ] && echo "delete any instance in the at the end"
PATH=\${PATH/%":\$SCCACHE_WRAPPER_BINDIR"/} # delete any instance in the at the end
[ "$DEBUG" != "" ] && echo "\$PATH"
${SCCACHE_BIN} ${COMPILER} "\$@"
EndofScript
}
_has_command SHELLLbash || {
cat > "./${COMPILER}" <<-EndofScript
#!$(command -v /bin/sh || command -v sh )
### #!/bin/sh
[ "$DEBUG" != "" ] && set -vx
SCCACHE_WRAPPER_BINDIR="\$(dirname \$0)"  # Intentionally don't resolve symlinks

# debug
[ "$DEBUG" != "" ] && PATH="\$SCCACHE_WRAPPER_BINDIR:\$PATH:\$SCCACHE_WRAPPER_BINDIR:/usrfoo:\$SCCACHE_WRAPPER_BINDIR"
#PATH="\$SCCACHE_WRAPPER_BINDIR:\$PATH"
#PATH="/usrfoo:\$SCCACHE_WRAPPER_BINDIR:\$PATH"
#PATH="\$PATH/usrfoo:\$SCCACHE_WRAPPER_BINDIR"

### PATH="/usr/local/lib/sccache:\$PATH:/usr/local/lib/sccache:\$PATH:/usr/local/lib/sccache"
#PATH="/usrfoo:/usr/local/lib/sccache:$PATH"
#PATH="$PATH/usrfoo:/usr/local/lib/sccache"

## str=$(printf '%s' "$str" | sed -e 's@/@a@g')
[ "$DEBUG" != "" ] && echo "\$PATH"
[ "$DEBUG" != "" ] && echo "sed: delete any instances in the middle"
[ "$DEBUG" != "" ] && echo "sed: delete any instance at the beginning"
[ "$DEBUG" != "" ] && echo "sed: delete any instance in the at the end"
PATH="\$(printf '%s\n' "\$PATH" | sed -e 's@:'\$SCCACHE_WRAPPER_BINDIR'[/]:@@g' -e 's@'\$SCCACHE_WRAPPER_BINDIR'[/]:@@g' -e 's@:'\$SCCACHE_WRAPPER_BINDIR'[/]@@g' )"
## PATH=\${PATH//":\$SCCACHE_WRAPPER_BINDIR:"/":"} # delete any instances in the middle
## PATH=\${PATH/#"\$SCCACHE_WRAPPER_BINDIR:"/} # delete any instance at the beginning
## PATH=\${PATH/%":\$SCCACHE_WRAPPER_BINDIR"/} # delete any instance in the at the end
[ "$DEBUG" != "" ] && echo "\$PATH"
${SCCACHE_BIN} ${COMPILER} "\$@"
EndofScript
}
chmod 755 ./${COMPILER}
done
Endofmessage



#echo "# foo" | $SudoE tee -a /usr/local/lib/sccache/sccache-wrapper
##echo "\\${SCCACHE_BIN} \\${COMPILER} \"$@\"" | $SudoE tee -a /usr/local/lib/sccache/sccache-wrapper
#echo "13 \${SCCACHE_BIN} \${COMPILER} \"\$@\"" | $SudoE tee -a /usr/local/lib/sccache/sccache-wrapper
#echo '14 \${SCCACHE_BIN} \${COMPILER} \"\$@\"' | $SudoE tee -a /usr/local/lib/sccache/sccache-wrapper
#echo '15 \${SCCACHE_BIN} \${COMPILER} \"$@\"' | $SudoE tee -a /usr/local/lib/sccache/sccache-wrapper
#printf '16 \${SCCACHE_BIN} \${COMPILER} \"$@\"\n' | $SudoE tee -a /usr/local/lib/sccache/sccache-wrapper
##echo "\${SCCACHE_BIN} \${COMPILER} \"\$@\"" | $SudoE tee -a /usr/local/lib/sccache/sccache-wrapper
##echo "\\${SCCACHE_BIN} \\${COMPILER} \"\$@\"" | $SudoE tee -a /usr/local/lib/sccache/sccache-wrapper
##echo "\\${SCCACHE_BIN} \\${COMPILER} \"\$\@\"" | $SudoE tee -a /usr/local/lib/sccache/sccache-wrapper
#echo "EndofScript" | $SudoE tee -a /usr/local/lib/sccache/sccache-wrapper
#echo "chmod 755 \"./\${COMPILER}\" " | $SudoE tee -a /usr/local/lib/sccache/sccache-wrapper
#echo "done" | $SudoE tee -a /usr/local/lib/sccache/sccache-wrapper



$Sudo chmod 755 /usr/lib/sccache/sccache-wrapper || $Sudo chmod 755 /usr/local/lib/sccache/sccache-wrapper
$Sudo chmod 755 /usr/lib/sccache/sccache-wrapper-sh || $Sudo chmod 755 /usr/local/lib/sccache/sccache-wrapper-sh
#[ -d /usr/lib/sccache/ ] && cd /usr/lib/sccache/ && $SudoE sccache-wrapper
#[ -d /usr/local/lib/sccache/ ] && cd /usr/local/lib/sccache/ && $SudoE sccache-wrapper
[ -d /usr/local/lib/sccache/ ] && $SudoE /usr/local/lib/sccache/sccache-wrapper
[ -d /usr/lib/sccache/ ] && $SudoE /usr/lib/sccache/sccache-wrapper
ls -latr /usr/lib/sccache/ /usr/local/lib/sccache/ /usr/local/bin/ ||:


# Prepend ccache into the PATH
# shellcheck disable=SC2016
grep -q /usr/local/lib/sccache ~/.bashrc || echo '[ -d /usr/local/lib/sccache/ ] && $( echo "$PATH" | grep -qv /usr/local/lib/sccache ) && export PATH="/usr/local/lib/sccache:$PATH" ' | tee -a ~/.bashrc
# shellcheck disable=SC2016
# DISABELD FOR sccache ### echo '[ -d /usr/lib64/sccache/ ] && export PATH="/usr/lib64/sccache:$PATH"' | tee -a ~/.bashrc
# shellcheck disable=SC2016
# DISABELD FOR sccache ### echo '[ -d /usr/lib/sccache/ ] && export PATH="/usr/lib/sccache:$PATH"' | tee -a ~/.bashrc
# Source bashrc to test the new PATH
# shellcheck disable=SC1090
source ~/.bashrc && echo "$PATH"

# cd /usr/local/bin && $Sudo ln -s /usr/local/lib/sccache/* .
### not work with sccache ### [ -d /usr/local/lib/sccache/ ] && cd /usr/local/bin && $Sudo ln -s -v /usr/local/lib/sccache/* . ||:
### not work with sccache ### [ -d /usr/lib/sccache/ ] && cd /usr/local/bin && $Sudo ln -s -v /usr/lib/sccache/* . ||:

echo "int x = 1;" > /tmp/test.c
echo "int x = $RANDOM;" > /tmp/test-RANDOM.c
ccache gcc /tmp/test.c -c -o /tmp/test.o ||:
ccache gcc /tmp/test-RANDOM.c -c -o /tmp/test-RANDOM.o ||:
sccache --show-stats ||:
sccache gcc /tmp/test.c -c -o /tmp/test.o ||:
sccache gcc /tmp/test-RANDOM.c -c -o /tmp/test-RANDOM.o ||:
ccache --show-stats ||:
sccache --show-stats ||:
gcc /tmp/test.c -c -o /tmp/test.o
gcc /tmp/test-RANDOM.c -c -o /tmp/test-RANDOM.o
ccache --show-stats ||:
sccache --show-stats ||:

#for t in gcc g++ cc c++ clang clang++; do ln -vs /usr/bin/ccache /usr/local/bin/$t; done
##for t in gcc g++ cc c++ clang clang++; do $Sudo ln -vs /usr/local/bin/sccache /usr/local/bin/$t; done
