# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]
# See env_vars.sh for extra environment variables
source gfortran-install/gfortran_utils.sh

function build_wheel {
    local lib_plat=$PLAT
    if [ -n "$IS_OSX" ]; then
        install_gfortran
        # Use fused openblas library
        lib_plat="intel"
    fi
    build_libs $lib_plat
    # Fix version error for development wheels by using bdist_wheel
    build_bdist_wheel $@
}

function build_libs {
    local plat=${1:-$PLAT}
    local tar_path=$(abspath $(get_gf_lib "openblas-${OPENBLAS_VERSION}" "$plat"))
    # Sudo needed for macOS
    local use_sudo=""
    [ -n "$IS_OSX" ] && use_sudo="sudo"
    (cd / && $use_sudo tar zxf $tar_path)
}

function get_test_cmd {
    local extra_argv=${1:-$EXTRA_ARGV}
    echo "import sys; import numpy; \
        sys.exit(not numpy.test('full', \
        extra_argv=[${extra_argv}]))"
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    if [ -n "$IS_OSX" ]; then  # Test both architectures on OSX
        # Skip f2py tests for 32-bit
        arch -i386 python -c "$(get_test_cmd "'--ignore=numpy/f2py', $EXTRA_ARGV")"
        arch -x86_64 python -c "$(get_test_cmd)"
    else
        python -c "$(get_test_cmd)"
    fi
    # Check bundled license file
    python ../check_license.py
    # Show BLAS / LAPACK used
    python -c 'import numpy; numpy.show_config()'
}
