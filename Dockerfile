# This dockerfile performs a multi-stage build.
# Stage 1) Creates a reference to the desired terraform version and
# downloads and compiles the tfmigrate executable.
###################################################################################################
# 1) Reference to terraform binary
###################################################################################################
FROM hashicorp/terraform:$terraform_version as tf-requirements
RUN git clone https://github.com/minamijoyo/tfmigrate
RUN cd tfmigrate/
RUN make install

###################################################################################################
# 2) Building the src code
###################################################################################################
FROM golang:1.19-alpine3.15
RUN apk update && apk add --no-cache bash git make

# Copying compiled executables from tf-requirements
COPY --from=tf-requirements /bin/terraform /usr/local/bin/
COPY --from=tf-requirements /bin/tfmigrate /usr/local/bin/

# Building the src code
WORKDIR $GOPATH/src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

ENTRYPOINT ["go", "run"]