#!/bin/bash

trap '{ echo -e "error ${?}\nthe command executing at the time of the error was\n${BASH_COMMAND}\non line ${BASH_LINENO[0]}" && tail -n 10 ${INSTALL_LOG} && exit $? }' ERR

declare -A NGX_MODULES
export DEBIAN_FRONTEND="noninteractive"

# Packages
export PACKAGES=(
	'mariadb-server'
	'pwgen'
)

install() {
    CODENAME=$(lsb_release -cs | tr '[A-Z]' '[a-z]')
    DISTRO=$(lsb_release -is | tr '[A-Z]' '[a-z]')

	apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db

	cat > /etc/apt/sources.list.d/mariadb.list <<EOF
deb http://ftp.nluug.nl/db/mariadb/repo/${MARIA_DB_VERSION}/${DISTRO} ${CODENAME} main
#deb-src http://ftp.nluug.nl/db/mariadb/repo/${MARIA_DB_VERSION}/${DISTRO} ${CODENAME} main
EOF
	apt-get update -q 2>&1 || return 1
	apt-get install -yq ${PACKAGES[@]} 2>&1 || return 1

    chmod +x /usr/local/bin/* || return 1

    #change bind address to 0.0.0.0
    sed -i -r 's/bind-address.*$/bind-address = 0.0.0.0/' /etc/mysql/my.cnf

    return 0
}

post_install() {
    apt-get autoremove 2>&1 || return 1
	apt-get autoclean 2>&1 || return 1
	rm -fr /var/lib/apt /usr/src/build 2>&1 || return 1

	return 0
}

build() {
	if [ ! -f "${INSTALL_LOG}" ]
	then
		touch "${INSTALL_LOG}" || exit 1
	fi

	tasks=(
        'install'
	)

	for task in ${tasks[@]}
	do
		echo "Running build task ${task}..." || exit 1
		${task} | tee -a "${INSTALL_LOG}" > /dev/null 2>&1 || exit 1
	done
}

if [ $# -eq 0 ]
then
	echo "No parameters given! (${@})"
	echo "Available functions:"
	echo

	compgen -A function

	exit 1
else
	for task in ${@}
	do
		echo "Running ${task}..." 2>&1  || exit 1
		${task} || exit 1
	done
fi
