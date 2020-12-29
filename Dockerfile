FROM debian:buster

ENV username=user1
ENV jobs=3

RUN apt-get update
RUN apt-get install -y autoconf                     \
                       automake                     \
                       binutils-dev                 \
                       bison                        \
                       build-essential              \
                       ccache                       \
                       clang                        \
                       cmake                        \
                       curl                         \
                       doxygen                      \
                       dvipng                       \
                       exuberant-ctags              \
                       flex                         \
                       flex                         \
                       gawk                         \
                       gcc                          \
                       git                          \
                       gperf                        \
                       graphviz                     \
                       gtkwave                      \
                       imagemagick                  \
                       libboost-all-dev             \
                       libboost-filesystem-dev      \
                       libboost-program-options-dev \
                       libboost-python-dev          \
                       libboost-system-dev          \
                       libbz2-dev                   \
                       libffi-dev                   \
                       libftdi-dev                  \
                       libgmp-dev                   \
                       libmotif-dev                 \
                       libqwt-dev                   \
                       libreadline-dev              \
                       libtool                      \
                       libx11-dev                   \
                       libxaw7-dev                  \
                       libxml2-dev                  \
                       libxpm-dev                   \
                       libxpm-dev                   \
                       libxt-dev                    \
                       libxt-dev                    \
                       mercurial                    \
                       pkg-config                   \
                       python                       \
                       python-dev                   \
                       python-qt4                   \
                       python-sphinx                \
                       python3                      \
                       python3-nose                 \
                       python3-venv                 \
                       python3.7                    \
                       python3.7-dev                \
                       qt4-dev-tools                \
                       rapidjson-dev                \
                       sudo                         \
                       tcl-dev                      \
                       texlive                      \
                       texlive-fonts-extra          \
                       texlive-lang-french          \
                       texlive-latex-extra          \
                       texlive-pictures             \
                       vim                          \
                       wget                         \
                       xdot                         \
                       xfig                         \
                       zlib1g-dev

# Setup users, and allow for x
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/${username} && \
    echo "${username}:x:${uid}:${gid}:${username},,,:/home/${username}:/bin/bash" >> /etc/passwd && \
    echo "${username}:x:${uid}:" >> /etc/group && \
    echo "${username} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${username} && \
    chmod 0440 /etc/sudoers.d/${username} && \
    chown ${uid}:${gid} -R /home/${username}

# Yosys
WORKDIR /workdir
RUN git clone https://github.com/cliffordwolf/yosys.git
WORKDIR /workdir/yosys
RUN make -j${jobs} &&\
    make install

# symbiosys
WORKDIR /workdir
RUN git clone https://github.com/YosysHQ/SymbiYosys.git SymbiYosys
WORKDIR /workdir/SymbiYosys
RUN make -j${jobs} &&\
    make install

# yices2
WORKDIR /workdir
RUN git clone https://github.com/SRI-CSL/yices2.git yices2
WORKDIR /workdir/yices2
RUN autoconf && ./configure
RUN make -j${jobs} &&\
    make install

# z3
WORKDIR /workdir
RUN git clone https://github.com/Z3Prover/z3.git z3
WORKDIR /workdir/z3
RUN python scripts/mk_make.py
WORKDIR /workdir/z3/build
RUN make -j${jobs} &&\
    make install

# super_prove
WORKDIR /workdir
RUN wget https://downloads.bvsrc.org/super_prove/super_prove-hwmcc17_14-Ubuntu_14.04-Release.tar.gz
RUN mkdir -p /usr/local/suprove &&\
    tar -C /usr/local/suprove -xzf super_prove-hwmcc17_14-Ubuntu_14.04-Release.tar.gz
COPY suprove /usr/local/bin/suprove

# Avy
WORKDIR /workdir
# FIXME some oddity with git submodule update --init inside docker
COPY extavy extavy
#RUN git clone https://bitbucket.org/arieg/extavy.git
#WORKDIR /workdir/extavy
#RUN git submodule update --init
WORKDIR /workdir/extavy/build
RUN cmake -DCMAKE_BUILD_TYPE=Release .. &&\
    make -j${jobs} &&\
    cp avy/src/avy avy/src/avybmc /usr/local/bin/

# boolector
WORKDIR /workdir
RUN git clone https://github.com/boolector/boolector
WORKDIR /workdir/boolector
RUN ./contrib/setup-btor2tools.sh &&\
    ./contrib/setup-lingeling.sh &&\
    ./configure.sh &&\
    make -C build -j${jobs} &&\
    cp build/bin/boolector build/bin/btor* /usr/local/bin/ &&\
    cp deps/btor2tools/bin/btorsim /usr/local/bin/

# nmigen
WORKDIR /workdir
RUN git clone https://github.com/m-labs/nmigen.git
WORKDIR /workdir/nmigen
# TODO develop?
# REV
RUN apt-get install -y python3-setuptools python3-wheel
RUN python3 setup.py install

# iie
WORKDIR /workdir
RUN git clone https://git.libre-riscv.org/git/ieee754fpu.git

# sfpy
WORKDIR /workdir
# FIXME
#RUN git clone --recursive https://github.com/billzorn/sfpy.git
COPY sfpy sfpy
WORKDIR /workdir/sfpy
RUN cd SoftPosit &&\
    git apply ../softposit_sfpy_build.patch &&\
    git apply /workdir/ieee754fpu/SoftPosit.patch &&\
    cd ../berkeley-softfloat-3 &&\
    git apply /workdir/ieee754fpu/berkeley-softfloat.patch
RUN apt-get install python3-pip
RUN python3 -m venv .env &&\
    . .env/bin/activate &&\
    pip3 install --upgrade -r requirements.txt &&\
    make lib -j${jobs} &&\
    make cython &&\
    make inplace -j${jobs} &&\
    make wheel &&\
    deactivate &&\
    pip3 install dist/sfpy*.whl

# alliance-check-toolkit
WORKDIR /workdir
RUN git clone https://gitlab.lip6.fr/jpc/alliance-check-toolkit.git

# alliance-check-toolkit and alliance
WORKDIR /workdir
ENV PATH="/usr/lib/ccache:${PATH}"
ENV ALLIANCE_TOP="/workdir/alliance/install"
ENV LD_LIBRARY_PATH="${ALLIANCE_TOP}/lib:${LD_LIBRARY_PATH}"
ENV LD_LIBRARY_PATH="${ALLIANCE_TOP}/lib64:${LD_LIBRARY_PATH}"
#RUN git clone https://gitlab.lip6.fr/jpc/alliance-check-toolkit.git &&\
RUN git clone https://www-soc.lip6.fr/git/alliance.git
# FIXME the documentation was being annoying to build with having to rerun latex more than once
RUN mkdir -p alliance/build alliance/install &&\
    cd alliance/alliance/src &&\
    ./autostuff &&\
    cd ../../build &&\
    ../alliance/src/configure --prefix=$ALLIANCE_TOP --enable-alc-shared &&\
    sed -e 's/ documentation$//g' Makefile -i'' &&\
    make -j1 install

# switch to normal user
#RUN echo "work:x:1001:${username}" >> /etc/group &&\
#    chmod -R g+rw /workdir &&\
#    chgrp -R work /workdir
ENV HOME /home/${username}
USER ${username}

# coriolis
RUN mkdir -p ${HOME}/coriolis-2.x/src &&\
    cd ${HOME}/coriolis-2.x/src &&\
    git clone https://www-soc.lip6.fr/git/coriolis.git
WORKDIR ${HOME}/coriolis-2.x/src/coriolis
RUN git checkout devel &&\
    ./bootstrap/ccb.py --project=coriolis --make="-j${jobs} install" &&\
    echo "eval '${HOME}/coriolis-2.x/src/coriolis/bootstrap/coriolisEnv.py'" >> ${HOME}/coriolisenv

# Needs this otherwise X doesn't display right
RUN echo "export QT_X11_NO_MITSHM=1" >> ${HOME}/.bash_profile
CMD cgt
