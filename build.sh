#!/usr/bin/env bash
# shellcheck disable=SC1039
# shellcheck disable=SC2034
# shellcheck disable=SC2181

set -e

PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

arch='amd64'
oldstable='stretch'
stable='buster'
testing='bullseye'
version='4.2'

function usage()
{
    cat <<EOF

NAME:
   build.sh - Docker images' builder of Debian.

USAGE:
   build.sh -d <dist>

OPTIONS:
   -h, --help           Show help

   -d, --dist           Choose Debian distribution
                        eg: lenny, squeeze, wheezy, jessie, stretch, buster

   -e, --extra-packages space separated list of extra packages
                        eg: -e foo bar baz
                        default: none

   -T  --extra-tag      Add a tag suffix to the created one
                        eg: buster-stable => buster-stable-{tag}
                        default: none

   -t, --timezone       Choose your preferred timezone
                        default: Europe/Amsterdam

   -u, --user           Docker Hub username or organisation
                        default: none

   -p, --push           Docker Hub push
                        default: no

   -l, --latest         Force the "latest"
                        default: buster

   -v, --verbose        Verbose mode

   -V, --version        Show version

VERSION:
   docker-debian version: ${version}

EOF
}

function docker_bootstrap()
{
    # variables
    image="/tmp/image-${distname}-${arch}"
    include="${include},\
             apt-transport-https,\
             apt-utils,\
             ca-certificates,\
             curl,\
             git,\
             locales"
    exclude="debconf-i18n,\
             git-man,\
             info,\
             man-db,\
             manpages"

    echo '-- bootstrap' 1>&3

    if [ "$(id -u)" -ne 0 ]
    then
        sudo='sudo'
    fi

    # clean old image
    if [ -d "/tmp/image-${distname}-${arch}" ]
    then
        ${sudo} rm -fr "${image}"
    fi

    # create minimal debootstrap image
    if [ ! -f "/usr/share/debootstrap/scripts/${distname}" ] || \
       [ ! -h "/usr/share/debootstrap/scripts/${distname}" ]
    then
        echo "File /usr/share/debootstrap/scripts/${distname} is missing." 1>&3
        echo "1.) did you install backports version of debootstrap ?" 1>&3
        echo "2.) ln -s sid /usr/share/debootstrap/scripts/${distname}" 1>&3
        exit 1
    else
        echo " * debootstrap ${image}" 1>&3
        ${sudo} debootstrap \
                --arch="${arch}" \
                --include="${include}" \
                --exclude="${exclude}" \
                --variant=minbase \
                "${distname}" \
                "${image}" \
                "${mirror}"
        if [ ${?} -ne 0 ]
        then
            echo "There is an issue Issue with debootstrap." 1>&3
            echo "Please run again with -v." 1>&3
            exit 1
        fi
    fi

    # create /etc/default/locale
    echo ' * /etc/default/locale' 1>&3
    cat <<EOF | \
        ${sudo} tee "${image}/etc/default/locale"
LANG=en_US.UTF-8
LANGUAGE=en_US.UTF-8
LC_COLLATE=en_US.UTF-8
LC_ALL=en_US.UTF-8
EOF

    # create /etc/timezone
    echo ' * /etc/timezone' 1>&3
    cat <<EOF | \
        ${sudo} tee "${image}/etc/timezone"
${timezone}
EOF

    # create /etc/resolv.conf
    echo ' * /etc/resolv.conf' 1>&3
    cat <<EOF | \
        ${sudo} tee "${image}/etc/resolv.conf"
nameserver 8.8.4.4
nameserver 8.8.8.8
EOF

    # create /etc/apt/sources.list
    echo ' * /etc/apt/sources.list' 1>&3
    ${sudo} cp -r "sources.list/${distname}" "${image}/etc/apt/sources.list"

    if [[ "${distname}" =~ ^(lenny|squeeze|wheezy|jessie)$ ]]
    then

        # create /etc/apt/apt.conf.d/ignore-release-date
        echo ' * /etc/apt/apt.conf.d/ignore-release-date' 1>&3
        cat <<EOF | \
            ${sudo} tee "${image}/etc/apt/apt.conf.d/ignore-release-date"
Acquire::AllowInsecureRepositories "true";
Acquire::Check-Valid-Until "false";
APT::Get::AllowUnauthenticated "true";
EOF

    else

        # create /etc/dpkg/dpkg.cfg.d/disable-doc
        echo ' * /etc/dpkg/dpkg.cfg.d/disable-doc'  1>&3
        cat <<EOF | \
            ${sudo} tee "${image}/etc/dpkg/dpkg.cfg.d/disable-doc"
path-exclude /usr/share/doc/*
path-include /usr/share/doc/*/copyright
path-exclude /usr/share/info/*
path-exclude /usr/share/man/*
EOF

    fi

    # create /etc/apt/apt.conf.d/force-ipv4
    echo ' * /etc/apt/apt.conf.d/force-ipv4' 1>&3
    cat <<EOF | \
        ${sudo} tee "${image}/etc/apt/apt.conf.d/force-ipv4"
Acquire::ForceIPv4 "true";
EOF

    # create /etc/apt/apt.conf.d/disable-auto-install
    echo ' * /etc/apt/apt.conf.d/disable-auto-install' 1>&3
    cat <<EOF | \
        ${sudo} tee "${image}/etc/apt/apt.conf.d/disable-auto-install"
APT::Install-Recommends "0";
APT::Install-Suggests "0";
EOF

    # create /etc/apt/apt.conf.d/disable-cache
    echo ' * /etc/apt/apt.conf.d/disable-cache' 1>&3
    cat <<EOF | \
        ${sudo} tee "${image}/etc/apt/apt.conf.d/disable-cache"
Dir::Cache::pkgcache "";
Dir::Cache::srcpkgcache "";
EOF

    # create /etc/apt/apt.conf.d/force-conf
    echo ' * /etc/apt/apt.conf.d/force-conf' 1>&3
    cat <<EOF | \
        ${sudo} tee "${image}/etc/apt/apt.conf.d/force-conf"
Dpkg::Options {
   "--force-confnew";
   "--force-confmiss";
}
EOF

    # create /etc/apt/apt.conf.d/disable-languages
    echo ' * /etc/apt/apt.conf.d/disable-languages' 1>&3
    cat <<EOF | \
        ${sudo} tee "${image}/etc/apt/apt.conf.d/disable-languages"
Acquire::Languages "none";
EOF

    # create /usr/bin/apt-clean
    echo ' * /usr/bin/apt-clean' 1>&3
    cat <<EOF | \
        ${sudo} tee "${image}/usr/bin/apt-clean"
#!/bin/bash

# Please read https://wiki.debian.org/ReduceDebian

find /usr/share/doc     -type f ! -name copyright -delete
find /usr/share/i18n    -type f ! -name en_US ! -name UTF-8.gz -delete
find /usr/share/locale  -type f -delete
find /usr/share/man     -type f -delete
find /var/cache/apt     -type f -delete
find /var/lib/apt/lists -type f -delete

apt-get autoclean       -qq -y
apt-get autoremove      -qq -y
apt-get clean           -qq -y
# EOF
EOF
    ${sudo} chmod 755 "${image}/usr/bin/apt-clean"

    # mount
    ${sudo} mount --bind /dev     "${image}/dev"
    ${sudo} mount --bind /dev/pts "${image}/dev/pts"
    ${sudo} mount --bind /proc    "${image}/proc"
    ${sudo} mount --bind /sys     "${image}/sys"

    # update root certificates
    ${sudo} mkdir -p "${image}/usr/local/share/"
    ${sudo} cp -r ca-certificates "${image}/usr/local/share/"

    # upgrade (without output...)
    echo ' * apt-get upgrade' 1>&3
    ${sudo} chroot "${image}" bash -c \
            "export DEBIAN_FRONTEND=noninteractive && \
             update-ca-certificates -f && \
             apt-get update && \
             apt-get upgrade -y && \
             apt-get dist-upgrade -y && \
             apt-clean"

    # unmount
    ${sudo} umount "${image}/dev/pts"
    ${sudo} umount "${image}/dev"
    ${sudo} umount "${image}/proc"
    ${sudo} umount "${image}/sys"

    # create archive
    if [ -f "${image}.tar" ]
    then
        ${sudo} rm "${image}.tar"
    fi
    ${sudo} tar -C "${image}" -c -f "${image}.tar" --numeric-owner .
}

# create images from bootstrap archive
function docker_import()
{
    echo "-- docker import from ${image}" 1>&3

    docker import "${image}.tar" "${user}debian:${distname}${tag}"
    docker run "${user}debian:${distname}${tag}" \
           echo " * build ${user}debian:${distname}${tag}" 1>&3
    docker tag "${user}debian:${distname}${tag}" "${user}debian:${distid}${tag}"
    docker run "${user}debian:${distid}${tag}" \
           echo " * build ${user}debian:${distid}${tag}" 1>&3

    for import in latest oldstable stable testing
    do
        if [ "${distname}" = "${!import}" ]
        then
            docker tag "${user}debian:${distname}${tag}" "${user}debian:${import}${tag}"
            docker run "${user}debian:${import}${tag}" \
                   echo " * build ${user}debian:${import}${tag}" 1>&3
        fi
    done
}

# push image to docker hub
function docker_push()
{
    echo "-- docker push" 1>&3
    echo " * push ${user}debian:${distname}${tag}" 1>&3
    docker push "${user}debian:${distname}${tag}"
    echo " * push ${user}debian:${distid}${tag}" 1>&3
    docker push "${user}debian:${distid}${tag}"

    for push in latest oldstable stable testing
    do
        if [ "${distname}" = "${!push}"  ]
        then
            echo " * push ${user}debian:${push}${tag}" 1>&3
            docker push "${user}debian:${push}${tag}"
        fi
    done
}

while getopts 'hd:e:T:t:u:plvV' OPTIONS
do
    case ${OPTIONS} in
        h)
            # -h / --help
            usage
            exit 0
            ;;
        d)
            # -d / --dist
            dist=${OPTARG}
            ;;
        e)
            # -e / --extra-packages
            extra=${OPTARG}
            ;;
        T)
            # -T / --tag
            tag=${OPTARG}
            ;;
        t)
            # -t / --timezone
            timezone=${OPTARG}
            ;;
        u)
            # -u / --user
            user="${OPTARG}/"
            ;;
        p)
            # -p / --push
            push='true'
            ;;
        l)
            # -l / --latest
            latest=${OPTARG}
            ;;
        v)
            # -v / --verbose
            verbose='true'
            ;;
        V)
            # -V / --version
            echo "${version}"
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

if [ ! -x "$(command -v sudo)" ]
then
    echo "Please install sudo (see README.md)"
    exit 1
fi

if [ ! -x "$(command -v debootstrap)" ]
then
    echo "Please install debootstrap (see README.md)"
    exit 1
fi

# -e / --extra-packages
if [ -z "${extra}" ]
then
    extra=''
fi

# -d / --dist
if [ -n "${dist}" ]
then
    case ${dist} in
        lenny|5|5.0)
            distname='lenny'
            distid='5'
            mirror='http://mirror.vpgrp.io/debian-archive/debian'
            ;;
        squeeze|6|6.0)
            distname='squeeze'
            distid='6'
            mirror='http://mirror.vpgrp.io/debian-archive/debian'
            ;;
        wheezy|7|7.0)
            distname='wheezy'
            distid='7'
            mirror='http://mirror.vpgrp.io/debian-archive/debian'
            ;;
        jessie|8|8.0)
            distname='jessie'
            distid='8'
            mirror='http://mirror.vpgrp.io/debian-archive/debian'
            ;;
        stretch|9|9.0)
            distname='stretch'
            distid='9'
            mirror='http://mirror.vpgrp.io/debian'
            include="gnupg2 ${extra}"
            ;;
        buster|10|10.0)
            distname='buster'
            distid='10'
            mirror='http://mirror.vpgrp.io/debian'
            include="gnupg2 ${extra}"
            ;;
        sid)
            distname='sid'
            distid='sid'
            mirror='http://mirror.vpgrp.io/debian'
            include="gnupg2 ${extra}"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
else
    usage
    exit 1
fi

# -t / --timezone
if [ -z "${timezone}" ]
then
    timezone='Europe/Amsterdam'
fi


# -T / --tag
if [ -z "${tag}" ]
then
    tag=''
else
    tag="-${tag}"
fi

# -u / --user
if [ -z "${user}" ]
then
    user=''
fi

# -l / --latest
if [ -z "${latest}" ]
then
    latest='buster'
fi

# -v / --verbose
if [ -z "${verbose}" ]
then
    exec 3>&1
    exec 1>/dev/null
    exec 2>/dev/null
else
    exec 3>&1
fi

docker_bootstrap
docker_import

if [ -n "${push}" ]
then
    docker_push
fi
# EOF
