# This dockerfile performs a multi-stage build.
# Stage 1) Builds the tfswitch executable.
# Stage 2) Builds the tfmigrate executable.
# Stage 3) Builds the job that wraps these previous two steps and executes the code
# in this repository.
###################################################################################################
# 1) Reference to tfswitch binary
###################################################################################################
FROM golang:1.18.2-alpine3.15 as tfswitch
RUN apk update && apk add --no-cache bash curl git make
RUN curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | bash

###################################################################################################
# 2) Building the tfmigrate binary
###################################################################################################
FROM golang:1.19-alpine3.15 as tfmigrate
RUN apk update && apk add --no-cache bash git make

# Building tfmigrate executable
COPY --from=tf /bin/terraform /usr/local/bin/
RUN git clone https://github.com/minamijoyo/tfmigrate /tfmigrate
WORKDIR /tfmigrate

RUN go mod download
RUN make install

###################################################################################################
# 3) Building the github action logic
###################################################################################################
FROM golang:1.19-alpine3.15
RUN apk update && apk add --no-cache bash git make

# Copying compiled executables from tf-requirements
COPY --from=tfswitch /usr/local/bin/tfswitch /usr/local/bin/
COPY --from=tf /bin/terraform /usr/local/bin/
COPY --from=tfmigrate go/bin/tfmigrate /usr/local/bin/

# Building the src code
WORKDIR $GOPATH/github-action-ftstate-migration/

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go install

ENTRYPOINT ["/go/bin/github-action-tfstate-migration"]
