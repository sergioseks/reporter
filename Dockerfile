# build
FROM golang:1.14.7-alpine3.12 AS build
WORKDIR /go/src/${owner:-github.com/sergioseks}/reporter
RUN apk update && apk add make git
COPY . .
RUN find . -mindepth 1 -maxdepth 1 \
           ! -name 'cmd' \
           ! -name 'grafana' \
           ! -name 'report' \
           ! -name 'util' \
           ! -name 'vendor' \
           -exec rm -rf {} + && \
    go install -v github.com/sergioseks/reporter/cmd/grafana-reporter

# create image
FROM alpine:3.12
COPY util/texlive.profile /

RUN PACKAGES="wget libswitch-perl" \
        && apk update \
        && apk add $PACKAGES \
        && apk add ca-certificates \
        && wget -qO- \
          "https://github.com/yihui/tinytex/raw/main/tools/install-unx.sh" | \
          sh -s - --admin --no-path \
        && mv ~/.TinyTeX /opt/TinyTeX \
        && /opt/TinyTeX/bin/*/tlmgr path add \
        && tlmgr path add \
        && chown -R root:adm /opt/TinyTeX \
        && chmod -R g+w /opt/TinyTeX \
        && chmod -R g+wx /opt/TinyTeX/bin \
        && tlmgr install epstopdf-pkg \
        # Cleanup
        && apk del --purge -qq $PACKAGES \
        && apk del --purge -qq \
        && rm -rf /var/lib/apt/lists/*


COPY --from=build /go/bin/grafana-reporter /usr/local/bin
ENTRYPOINT [ "/usr/local/bin/grafana-reporter" ]
