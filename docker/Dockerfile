FROM	debian:buster-slim

ARG	DEBIAN_FRONTEND=noninteractive

RUN	sh -ex; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		curl ca-certificates \
		wget unzip rsync \
	;:

ADD	./fasm fasm

WORKDIR	/fasm

RUN	sh -ex; \
	./mkfasm.sh \
	;:

ENTRYPOINT ["/bin/bash", "-c", "exec env HOME=$PWD /bin/bash"]
