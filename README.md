# debian

1. [Overview](#overview)
1. [Description](#description)
1. [Tags](#tags)
1. [Setup](#setup)
1. [Usage](#usage)
1. [Limitations](#limitations)
1. [Development](#development)
1. [Miscellaneous](#miscellaneous)

## Overview

Debian is a  free operating system (OS) for your  computer. An operating system
is the set of basic programs and utilities that make your computer run.

[debian.org](https://www.debian.org/)

## Description

Use this script to build your own base system.

We've included the last ca-certificates files  in the repository to ensure that
all of our images are accurates.

## Tags

Supported tags.

### Without systemd

- 7,  wheezy
- 8,  jessie
- 9,  stretch
- 10, buster, oldstable
- 11, bullseye, stable, latest

### With systemd

- 9-systemd, stretch-systemd,
- 8-systemd, jessie-systemd
- 10-systemd, buster-systemd
- 11-systemd, bullseye-systemd

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
(7.0), jessie (8.0),  stretch (9.0), buster (10.0) or bullseye  (11.0) you want
(bullseye  will be  the 'latest'  tag)  and you  need  to choose  you user  (or
organization) name on Docker Hub.

Show help.

```bash
./build.sh -h
```

Build your own Debian image (eg. bullseye).

```bash
./build.sh -d bullseye -u vptech
```

Build your own Debian image (eg. buster) and push it on the Docker Hub.

```bash
./build.sh -d buster -u vptech -p
```

Build your own Debian image (eg. buster) with systemd and vim.

```bash
./build.sh -d bullseye -e "systemd vim" -T "systemd"
```

## Limitations

Only work on Debian, Devuan and Ubuntu.

## Development

Please read carefully [CONTRIBUTING.md](CONTRIBUTING.md) before making a merge
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
