#!/bin/bash
set -e

# Optional environment:
#   ANTLR_VERSION   ANTLR C++ runtime version to build (default 4.13.2)
#   EXTRA_PACKAGES  additional OS packages to install (e.g. for CI)

ANTLR_VERSION="${ANTLR_VERSION:-4.13.2}"
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# Use sudo only when not already root (containers usually run as root without sudo)
SUDO=
if [ "$(id -u)" -ne 0 ]; then
    SUDO=sudo
fi

install_packages() {
    echo "Installing OS packages..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
    fi

    case "$ID" in
        ubuntu|debian)
            export DEBIAN_FRONTEND=noninteractive
            $SUDO apt-get update
            $SUDO apt-get install -y uuid-dev flex openjdk-21-jre \
                libicu-dev libxml2-dev openssl libssl-dev python3-dev \
                libossp-uuid-dev libpq-dev pkg-config g++ build-essential bison \
                wget unzip $EXTRA_PACKAGES
            ;;
        amzn|rhel|centos)
            $SUDO yum install -y libicu-devel libxml2-devel \
                openssl-devel uuid-devel postgresql-devel gcc gcc-c++ java \
                make bison flex python3-devel \
                wget unzip tar gzip which $EXTRA_PACKAGES
            ;;
        *)
            echo "Unsupported OS: ${ID:-unknown}. See contrib/README.md."
            exit 1
            ;;
    esac
}

install_cmake() {
    if command -v cmake &>/dev/null; then
        echo "cmake already installed: $(cmake --version | head -1)"
        return
    fi

    echo "Installing cmake..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
    fi

    case "$ID" in
        ubuntu|debian)
            $SUDO apt-get install -y cmake
            ;;
        amzn|rhel|centos)
            $SUDO yum install -y cmake3
            $SUDO alternatives --install /usr/bin/cmake cmake /usr/bin/cmake3 1
            ;;
    esac
}

install_antlr() {
    if [ -f "/usr/local/lib/libantlr4-runtime.so.${ANTLR_VERSION}" ] || \
       [ -f "/usr/local/lib64/libantlr4-runtime.so.${ANTLR_VERSION}" ]; then
        echo "ANTLR ${ANTLR_VERSION} runtime already installed."
        return
    fi

    echo "Installing ANTLR4 C++ runtime ${ANTLR_VERSION}..."

    local jar="$REPO_DIR/contrib/babelfishpg_tsql/antlr/thirdparty/antlr/antlr-${ANTLR_VERSION}-complete.jar"
    if [ -f "$jar" ]; then
        $SUDO cp "$jar" /usr/local/lib/
    fi

    local work_dir=$(mktemp -d)
    cd "$work_dir"
    wget -q "http://www.antlr.org/download/antlr4-cpp-runtime-${ANTLR_VERSION}-source.zip"
    unzip -qd antlr4 "antlr4-cpp-runtime-${ANTLR_VERSION}-source.zip"
    cd antlr4 && mkdir -p build && cd build
    cmake .. -DANTLR_JAR_LOCATION="/usr/local/lib/antlr-${ANTLR_VERSION}-complete.jar" -DCMAKE_INSTALL_PREFIX=/usr/local -DANTLR_BUILD_CPP_TESTS=OFF
    make -j$(nproc)
    $SUDO make install
    rm -rf "$work_dir"

    # Symlink lib64 → lib if needed (AL2/RHEL installs to lib64)
    if [ -f "/usr/local/lib64/libantlr4-runtime.so.${ANTLR_VERSION}" ] && \
       [ ! -f "/usr/local/lib/libantlr4-runtime.so.${ANTLR_VERSION}" ]; then
        $SUDO ln -s "/usr/local/lib64/libantlr4-runtime.so.${ANTLR_VERSION}" \
                    "/usr/local/lib/libantlr4-runtime.so.${ANTLR_VERSION}"
    fi
}

# Main
install_packages
install_cmake
install_antlr

echo ""
echo "Dependencies installed successfully."
echo "Next: run dev-tools.sh initpg, initdb, buildbbf, initbbf"
