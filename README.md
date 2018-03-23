# docker-debian

[![License][license-img]][license-href]
[![docker][docker-img]][docker-href]

1. [Overview](#overview)
2. [Description](#description)
3. [Tags](#tags)
4. [Setup](#setup)
5. [Usage](#usage)
6. [Limitations](#limitations)
7. [Development](#development)
8. [Miscellaneous](#miscellaneous)

## Overview

Debian is a  free operating system (OS) for your  computer. An operating system
is the set of basic programs and utilities that make your computer run.

[debian.org][overview-href]

## Description

Use this script to build your own base system.

We've included the last ca-certificates files  in the repository to ensure that
all of our images are accurates.

## Tags

Supported tags.

- 5, lenny
- 6, squeeze
- 7, wheezy
- 8, jessie, oldstable
- 9, stretch, stable, latest
- 10, buster, sid

## Setup

On Debian you need sudo permissions and the following packages:

```bash
# if you build on wheezy please use backports version of debootstrap
sudo apt-get -qq -y install debootstrap
```

On Devuan you need sudo permissions and the following packages:

```bash
sudo apt-get -qq -y install debian-keyring debian-archive-keyring debootstrap
```

On Ubuntu you need sudo permissions and the following packages:

```bash
sudo apt-get -qq -y install debian-keyring debian-archive-keyring debootstrap
```

You also need to be in the docker group to use Docker.

```bash
sudo usermod -a -G docker ${USER}
```

Finally you need to login on Docker Hub.

```bash
docker login
```

## Usage

You first need to choose which  dist between lenny (5.0), squeeze (6.0), wheezy
(7.0), jessie (8.0), stretch (9.0) and  buster (10.0) you want (stretch will be
the 'latest'  tag) and you  need to choose you  user (or organization)  name on
Docker Hub.

Show help.

```bash
./build.sh -h
```

Build your own Debian image (eg. jessie).

```bash
./build.sh -d jessie -u vpgrp
```

Build your own Debian image (eg. stretch) and push it on the Docker Hub.

```bash
./build.sh -d stretch -u vpgrp -p
```

## Limitations

Only work on Debian, Devuan and Ubuntu.

## Development

Please read carefully [CONTRIBUTING.md][contribute-href]  before making a merge
request.

## Miscellaneous

```
    ╚⊙ ⊙╝
  ╚═(███)═╝
 ╚═(███)═╝
╚═(███)═╝
 ╚═(███)═╝
  ╚═(███)═╝
   ╚═(███)═╝
```

[license-img]: https://img.shields.io/badge/license-Apache-blue.svg
[license-href]: LICENSE
[docker-img]: https://img.shields.io/docker/pulls/vpgrp/debian.svg
[docker-href]: https://registry.hub.docker.com/u/vpgrp/debian
[overview-href]: https://www.debian.org/
[contribute-href]: CONTRIBUTING.md
