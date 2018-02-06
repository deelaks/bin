#!/usr/bin/env bash
# set -x
# set -u
set -e

ME=$(basename "$0")
MYDIR=$(dirname "$0")
MYDIR=$(cd "$MYDIR"/.. && pwd)

export ME

#####################################################
#
# Function
#
#####################################################

list_containers () {
    docker ps -a
}

list_images () {
    docker images
}

list_unused_containers () {
    docker ps -a -q -f status=exited
}

list_unused_volumes () {
    docker volume ls -qf dangling=true
}

list_unused_images () {
    docker images -f dangling=true -q
}

list_networks () {
    docker network ls -f 'driver=bridge'
}

rm_unused_containers () {
    #docker rm "$1"
    docker ps -a -q -f status=exited | xargs docker stop
    docker ps -a -q -f status=exited | xargs docker rm
}

rm_unused_volumes () {
    docker volume ls -qf dangling=true | xargs docker volume rm
}

rm_unused_images () {
    docker images -f dangling=true -q | xargs docker rmi
}

rm_unused_networks () {
    docker network prune -f
}

is_old_mutable_tags () {
    which remove_old_mutable_tags.sh
}

stop_docker-registry () {
    docker stop docker-registry
}

garbage_docker-registry () {
    docker run -it --name gc --rm --volumes-from docker-registry registry:2 garbage-collect /etc/docker/registry/config.yml
}

start_docker-registry () {
    docker start docker-registry
}

info () {
echo "
#####################################################
#
# "$1"
#
#####################################################
"
}

#####################################################
#
# Main
#
#####################################################

OPTSPECS[a]="IMAGES:yes: List Images:no"
OPTSPECS[b]="CONTAINERS:yes: List Containers:no"
OPTSPECS[c]="UCONTAINERS:yes: List Unused Containers:no"
OPTSPECS[d]="UVOLUMES:yes: List Unused Volumes:no"
OPTSPECS[e]="UIMAGES:yes: List Unused Images:no"
OPTSPECS[f]="LIST:yes: List All List:no"
OPTSPECS[g]="REMOVE:yes: Remove All List:no"
OPTSPECS[i]="GARBAGE:yes: Docker Garbage Collector:no"

export OPTSPECS

get_options "$@"


if [[ "$IMAGES" != no ]]; then
    info 'list images'
    list_images

fi

if [[ "$CONTAINERS" != no ]]; then
    info 'list containers'
    list_containers
fi

if [[ "$UCONTAINERS" != no ]]; then
    info 'list unused containers'
    list_unused_containers
fi

if [[ "$UVOLUMES" != no ]]; then
    info 'list unused volumes'
    list_unused_volumes
fi

if [[ "$UIMAGES" != no ]]; then
    info 'list unused images'
    list_unused_images
fi

if [[ "$LIST" != no ]]; then
    info 'list images'
    list_images

    info 'list unused images'
    list_unused_images

    info 'list containers'
    list_containers

    info 'list unused containers'
    list_unused_containers

    info 'list unused volumes'
    list_unused_volumes

    info 'list bridge networks'
    list_networks
fi

if [[ "$REMOVE" != no ]]; then

    if [[ -n  $(list_unused_containers) ]]; then
    info 'remove unused containers'
    rm_unused_containers
    fi

    if [[ -n  $(list_unused_volumes) ]]; then
    info 'remove unused volumes'
    rm_unused_volumes
    fi

    if [[ -n  $(list_unused_images) ]]; then
    info 'remove unused images'
    rm_unused_images
    fi

    if [[ -n  $(list_networks) ]]; then
    info 'remove unused networks'
    rm_unused_networks
    fi

fi

if [[ "$GARBAGE" != no ]]; then

    if [[ -n $(is_old_mutable_tags) ]]; then
        info 'remove_old_mutable_tags'
        remove_old_mutable_tags.sh
        info 'stop docker-registry'
        stop_docker-registry
        info 'garbage-collect docker-registry'
        garbage_docker-registry
        info 'start docker-registry'
        start_docker-registry
    else
        info 'remove_old_mutable_tags.sh is not installed'
    fi

fi








