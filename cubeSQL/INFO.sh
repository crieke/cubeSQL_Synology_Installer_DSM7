#!/bin/bash
# Copyright (c) 2000-2020 Synology Inc. All rights reserved.

source /pkgscripts/include/pkg_util.sh

package="cubeSQL"
displayname="cubeSQL"
version=`date +%Y%m%d`
maintainer="SQLabs srl"
maintainer_url="https://sqlabs.com/"
distributor="Synology Installer by Christopher Rieke"
distributor_url="https://rie.ke"
helpurl="https://sqlabs.com/contacts"
arch="i686, x86_64"
description="cubeSQL is a fully featured and high performance relational database management system built on top of the sqlite database engine. We developed the first commercial grade DBMS based on sqlite back in 2005 and over the years we continued to improve our server to better suit all our customer's needs. cubeSQL is the final result of all our efforts."
support_url="https://sqlabs.com/contacts"
os_min_ver="7.0-40000"
thirdparty="yes"
[ "$(caller)" != "0 NULL" ] && return 0
pkg_dump_info
