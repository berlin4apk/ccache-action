#!/usr/bin/env bash

set -xv

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

# PN=$(dirname "$0")

[ -d /usr/local/bin/ ] || $Sudo mkdir -p /usr/local/bin/
[ -d /usr/local/lib/sccache/ ] || $Sudo mkdir -p /usr/local/lib/sccache/
# [ -e /usr/local/bin/sccache ] || $Sudo touch /usr/local/bin/ccache
# $Sudo "$PN"/update-ccache-symlinks.pl



          # By default, sccache will fail your build if it fails to successfully communicate with its associated server. To have sccache instead gracefully failover to the local compiler without stopping, set the environment variable SCCACHE_IGNORE_SERVER_IO_ERROR=1.
          echo build-with-SCCACHE
          # see https://github.com/mozilla/sccache/issues/1155#issuecomment-1097557677
[ -d /usr/local/lib/sccache/ ] || $Sudo mkdir -p /usr/local/lib/sccache/
cat <<EOF1 | $SudoE tee /usr/local/lib/sccache/sccache-wrapper2
#!/usr/bin/env bash
SCCACHE_BIN="\$(command -v sccache || echo sccache )"
cd "\$(dirname "\$0")"
for COMPILER in "c++" "c89" "c99" "cc" "clang" "clang++" "cpp" "g++" "gcc" "rustc" "x86_64-pc-linux-gnu-c++" "x86_64-pc-linux-gnu-cc" "x86_64-pc-linux-gnu-g++" "x86_64-pc-linux-gnu-gcc" "arm-none-eabi-c++" "arm-none-eabi-cc" "arm-none-eabi-g++" "arm-none-eabi-gcc" "aarch64-linux-gnu-c++" "aarch64-linux-gnu-cc" "aarch64-linux-gnu-g++" "aarch64-linux-gnu-gcc" "arm-none-eabi-c++" "arm-none-eabi-cc" "arm-none-eabi-g++" "arm-none-eabi-gcc"; do
cat > "./\${COMPILER}" <<-EOF
#!/bin/bash
SCCACHE_WRAPPER_BINDIR="\$(dirname \${BASH_SOURCE[0]})"  # Intentionally don't resolve symlinks
PATH=\${PATH//":\$SCCACHE_WRAPPER_BINDIR:"/":"} # delete any instances in the middle
PATH=\${PATH/#"\$SCCACHE_WRAPPER_BINDIR:"/} # delete any instance at the beginning
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
cat <<EOF1 | $SudoE tee /usr/local/lib/sccache/sccache-wrapper
#!/usr/bin/env bash
SCCACHE_BIN="\$(command -v sccache || echo sccache )"
cd "\$(dirname "\$0")"
for COMPILER in "c++" "c89" "c99" "cc" "clang" "clang++" "cpp" "g++" "gcc" "rustc" "x86_64-pc-linux-gnu-c++" "x86_64-pc-linux-gnu-cc" "x86_64-pc-linux-gnu-g++" "x86_64-pc-linux-gnu-gcc" "arm-none-eabi-c++" "arm-none-eabi-cc" "arm-none-eabi-g++" "arm-none-eabi-gcc" "aarch64-linux-gnu-c++" "aarch64-linux-gnu-cc" "aarch64-linux-gnu-g++" "aarch64-linux-gnu-gcc" "arm-none-eabi-c++" "arm-none-eabi-cc" "arm-none-eabi-g++" "arm-none-eabi-gcc"; do
cat > "./\${COMPILER}" <<-EOF
#!/bin/bash
SCCACHE_WRAPPER_BINDIR="\$(dirname \${BASH_SOURCE[0]})"  # Intentionally don't resolve symlinks
PATH=\${PATH//":\$SCCACHE_WRAPPER_BINDIR:"/":"} # delete any instances in the middle
PATH=\${PATH/#"\$SCCACHE_WRAPPER_BINDIR:"/} # delete any instance at the beginning
PATH=\${PATH/%":\$SCCACHE_WRAPPER_BINDIR"/} # delete any instance in the at the end
# /usr/bin/sccache \${COMPILER} "\$@"
\${SCCACHE_BIN} \${COMPILER} "$@"
\${SCCACHE_BIN} \${COMPILER} "\\$\\@"
\${SCCACHE_BIN} \${COMPILER} "\$\@"
\${SCCACHE_BIN} \${COMPILER} "\$@"
EOF
chmod 755 "./\${COMPILER}"
done
Endofmessage

$Sudo chmod 755 /usr/lib/sccache/sccache-wrapper || $Sudo chmod 755 /usr/local/lib/sccache/sccache-wrapper
$SudoE /usr/lib/sccache/sccache-wrapper || $SudoE /usr/local/lib/sccache/sccache-wrapper
ls -latr /usr/lib/sccache/ /usr/local/lib/sccache/ /usr/local/bin/ ||:


# Prepend ccache into the PATH
# shellcheck disable=SC2016
echo '[ -d /usr/local/lib/ccache/ ] && export PATH="/usr/local/lib/ccache:$PATH"' | tee -a ~/.bashrc
# shellcheck disable=SC2016
echo '[ -d /usr/lib64/sccache/ ] && export PATH="/usr/lib64/sccache:$PATH"' | tee -a ~/.bashrc
# shellcheck disable=SC2016
echo '[ -d /usr/lib/sccache/ ] && export PATH="/usr/lib/sccache:$PATH"' | tee -a ~/.bashrc
# shellcheck disable=SC2016
echo '[ -d /usr/local/lib/sccache/ ] && export PATH="/usr/local/lib/sccache:$PATH"' | tee -a ~/.bashrc
# Source bashrc to test the new PATH
# shellcheck disable=SC1090
source ~/.bashrc && echo "$PATH"

cd /usr/local/bin && $Sudo ln -s /usr/local/lib/sccache/* .
#for t in gcc g++ cc c++ clang clang++; do ln -vs /usr/bin/ccache /usr/local/bin/$t; done
for t in gcc g++ cc c++ clang clang++; do $Sudo ln -vs /usr/local/bin/sccache /usr/local/bin/$t; done
