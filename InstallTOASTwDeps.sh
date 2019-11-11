#!/bin/bash
set -eu

rm -r $HOME/venv-toast/
prefix="$HOME/venv-toast"

module purge
module load NiaEnv/2019b
module load autotools git cmake
module load intelpython3/2019u3
module load intel/2019u3 intelmpi cfitsio/3.450 fftw/3.3.8

virtualenv --system-site-packages "$prefix"

set +u
source "$prefix/bin/activate"
set -u

LDSHARED=$(python -c "from distutils import sysconfig; print(sysconfig.get_config_var('LDSHARED'))")
LDSHARED="${LDSHARED/gcc/$CC}"
LDSHARED="$LDSHARED" pip --no-cache-dir install pyephem astropy healpy mpi4py numpy scipy matplotlib

##temp build directory to install libconviqt
cd $(mktemp -d)

git clone https://github.com/hpc4cmb/libconviqt.git
cd libconviqt
./autogen.sh
./configure --prefix="$prefix" --with-lapack="-lmkl_rt" --with-blas="-lmkl_rt"
make -j 4
make check -j 4
make install -j 4
##install Python wrapper
cd python
python setup.py install
python setup.py test

cd $prefix

##temp build directory to install libmadam
cd $(mktemp -d)

git clone https://github.com/hpc4cmb/libmadam.git
cd libmadam
./autogen.sh
./configure --prefix="$prefix" --with-lapack="-lmkl_rt" --with-blas="-lmkl_rt"
make -j 4
make check -j 4
make install -j 4
##install Python wrapper
cd python
python setup.py install
python setup.py test
cd ../..

##temp build directory to install TOAST
cd $(mktemp -d)

git clone https://github.com/hpc4cmb/toast.git
cd toast
cmake -DCMAKE_INSTALL_PREFIX="$prefix" -DBLAS_LIBRARIES="-lmkl_rt" -DLAPACK_LIBRARIES="-lmkl_rt"
make -j 4
make install -j 4
