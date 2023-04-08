# build stage
FROM golang:1.14.7-alpine3.12 AS build

# set workdir
WORKDIR /go/src/${owner:-github.com/sergioseks}/reporter

# install dependencies
RUN apk update \
    && apk add git

# copy source code
COPY . .

# install app
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

# copy profile
COPY util/texlive.profile /

# install packages
RUN PACKAGES="wget perl-switch" \
        && apk update \
        && apk add $PACKAGES \
        && apk add ca-certificates \
        && apk add fontconfig \
        && wget -qO- \
          "https://raw.githubusercontent.com/rstudio/tinytex/main/tools/install-unx.sh" | \
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

# copy binary from stage build to user bin directory
COPY --from=build /go/bin/grafana-reporter /usr/local/bin

# set command to run
ENTRYPOINT [ "/usr/local/bin/grafana-reporter" ]
