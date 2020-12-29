SHELL=/bin/sh

TAG=libreriscv

# Easier to interface with my firewall setup...
#EXTRA_BUILD_ARGS = --network host
#EXTRA_RUN_ARGS   = --network host

EXTRA_BUILD_ARGS ?=
EXTRA_RUN_ARGS   ?=

build: extavy sfpy
	podman build . \
		-t $(TAG) \
		$(EXTRA_BUILD_ARGS) \
		2>&1 | tee $$(date --iso-8601=seconds).log

run:
	podman run -ti --rm \
		-e DISPLAY=$$DISPLAY \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		$(EXTRA_RUN_ARGS) \
		libreriscv bash

# FIXME I was running into issues with --recursive inside docker so instead I
#       clone them outside of the dockerfile and copy them into the container...
extavy:
	git clone --recursive https://bitbucket.org/arieg/extavy
sfpy:
	git clone --recursive https://github.com/billzorn/sfpy.git
