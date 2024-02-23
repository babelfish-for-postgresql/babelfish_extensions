#!/bin/sh

set -e

if [ ! $1 ]; then
    echo "Prerequisites:"
    echo "  (1) postgresql_modified_for_babelfish, babelfish_extensions, and Dockerfile should be in the same workspace."
    echo "  (2) should be executed in the \"babelfish_extension\" directory."
    echo ""
    echo "  builddocker"
    echo "      build docker image environment for babelfish"
    echo ""
    echo "  rundocker"
    echo "      run docker container for babelfish"
    echo ""
    echo "  execdocker"
    echo "      launch a terminal within babelfish container"
    echo ""
    echo "  initdb"
    echo "      init data directory + modify postgresql.conf + restart db"
    echo ""
    echo "  initbbf"
    echo "      execute babelfish_extensions/test/JDBC/init.sh"
    echo ""
    echo "  buildpg"
    echo "      build postgresql_modified_for_babelfish + restart db"
    echo ""
    echo "  buildbbf"
    echo "      build babelfish_extensions + restart db"
    echo ""
    echo "  buildall"
    echo "      build postgresql_modified_for_babelfish + build babelfish_extensions + restart db"
    exit 0
fi


if [ ! -e "./Dockerfile" ]; then
    echo "Error: Docker file \"Dockerfile\" should exist in the folder." 1>&2
    exit 1
fi

if [ ! -d "./postgresql_modified_for_babelfish" ]; then
    echo "Error: Directory \"postgresql_modified_for_babelfish\" should exist in the same folder." 1>&2
    exit 1
fi

if [ ! -d "./babelfish_extensions" ]; then
    echo "Error: Directory \"babelfish_extensions\" should exist in the same folder." 1>&2
    exit 1
fi

builddocker(){
    if [[ "$(docker images -q babelfish_image:latest 2> /dev/null)" == "" ]]; then #if image does not exist then build it
        docker build -t babelfish_image --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) .
    else
        echo "Images already exist."
    fi
}
rundocker(){
    if [ ! "$(docker ps -a | grep babelfish_container)" ]; then
        docker run -d -it -p 5432:5432 -v $(pwd):/src --name babelfish_container babelfish_image
    else
        docker restart babelfish_container
    fi
}
execdocker(){
    docker exec -it babelfish_container bash
}


if [ "$1" == "builddocker" ]; then
    builddocker
    exit 0
elif [ "$1" == "rundocker" ]; then
    rundocker
    exit 0
elif [ "$1" == "execdocker" ]; then
    execdocker
    exit 0
elif [ "$1" == "initdb" ]; then
    docker exec -it --user user babelfish_container sh /src/dev_tool_inner.sh initdb
    exit 0
elif [ "$1" == "initbbf" ]; then
    docker exec -it --user user babelfish_container sh /src/dev_tool_inner.sh initbbf
    exit 0
elif [ "$1" == "buildpg" ]; then
    docker exec -it --user user babelfish_container sh /src/dev_tool_inner.sh buildpg
    exit 0
elif [ "$1" == "buildbbf" ]; then
    docker exec -it --user user babelfish_container sh /src/dev_tool_inner.sh buildbbf
    exit 0
elif [ "$1" == "buildall" ]; then
    docker exec -it --user user babelfish_container sh /src/dev_tool_inner.sh buildall
    exit 0
fi