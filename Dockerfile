FROM library/rust:latest as builder

WORKDIR /opt
ARG veilid_version=main

RUN git clone --branch ${veilid_version} --depth 1 --recurse-submodules https://gitlab.com/veilid/veilid.git
WORKDIR /opt/veilid

RUN apt update -y && apt install -y checkinstall cmake build-essential && && ./scripts/earthly/install_capnproto.sh 1 && ./scripts/earthly/install_protoc.sh
RUN cd veilid-server && cargo build --release
RUN cd veilid-cli && cargo build --release

FROM library/ubuntu:22.04

COPY --from=builder /opt/veilid/target/release/veilid-server /usr/local/bin/veilid-server
COPY --from=builder /opt/veilid/target/release/veilid-cli /usr/local/bin/veilid-cli


RUN apt update -y && apt install -y tini && rm -rf /var/lib/apt/lists/*

EXPOSE 5150/tcp
EXPOSE 5150/udp
EXPOSE 5959/tcp

CMD ["/usr/bin/tini","--","/usr/local/bin/veilid-server","--foreground"]
