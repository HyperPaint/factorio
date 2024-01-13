#!/bin/sh

repository=hyperpaint
name=factorio
version=1.1.100
build=1

docker build -t $repository/$name:$version .
docker tag $repository/$name:$version $repository/$name:$version-$build
