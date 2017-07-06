#!/bin/sh

mkdir -p /koolshare
export KSROOT=/koolshare

_quote() {
	echo $1 | sed 's/[]\/()$*.^|[]/\\&/g'
}

pc_insert() {
	PATTERN=$(_quote "$1")
	CONTENT=$(_quote "$2")
	sed -i "/$PATTERN/a$CONTENT" $3
}

softcenter_install() {
	#remove useless files
	if [ -d "$KSROOT/init.d" ]; then
		rm -rf $KSROOT/init.d/S01Skipd.sh >/dev/null 2>&1
		rm -rf $KSROOT/init.d/S10softcenter.sh >/dev/null 2>&1
	fi
	
	# remove database if version below 0.1.5
	if [ -f "$KSROOT/bin/versioncmp" ] && [ -f "$KSROOT/bin/dbus" ] && [ -n `pidof skipd` ];then
		version_installed=`$KSROOT/bin/dbus get softcenter_version`
		version_comp=`$KSROOT/bin/versioncmp "$version_installed" "0.1.5"`
		if [ "$version_comp" == "1" ];then
			killall skipd
			rm -rf /jffs/db
			rm -rf $KSROOT/bin/skipd
		fi
	fi

	# install software center files
	if [ -d "/tmp/softcenter" ]; then
		mkdir -p $KSROOT
		mkdir -p $KSROOT/webs/
		mkdir -p $KSROOT/init.d/
		mkdir -p $KSROOT/webs/res/
		mkdir -p $KSROOT/bin/
		cp -rf /tmp/softcenter/webs/* $KSROOT/webs/
		cp -rf /tmp/softcenter/bin/* $KSROOT/bin/
		cp -rf /tmp/softcenter/perp $KSROOT/
		cp -rf /tmp/softcenter/scripts $KSROOT/
		cp -rf /tmp/softcenter/module $KSROOT/
		chmod 755 $KSROOT/bin/*
		chmod 755 $KSROOT/perp/*
		chmod 755 $KSROOT/perp/.boot/*
		chmod 755 $KSROOT/perp/.control/*
		chmod 755 $KSROOT/scripts/*
		chmod 755 $KSROOT/perp/httpdb/*
		chmod 755 $KSROOT/perp/skipd/*

		rm -rf /tmp/softcenter*
		mkdir -p /tmp/upload

		[ ! -L $KSROOT/bin/netstat ] && ln -sf $KSROOT/bin/koolbox $KSROOT/bin/netstat
		[ ! -L $KSROOT/bin/diff ] && ln -sf $KSROOT/bin/koolbox $KSROOT/bin/diff
		[ ! -L $KSROOT/webs/res ] && ln -sf $KSROOT/res $KSROOT/webs/res
		
		nvram unset at_nav
		nvram commit

		# re-make tomato.js everytime incase of fw updating
		cp -rf /www/tomato.js /jffs/koolshare/webs
		pc_insert "admin-upgrade.asp" "'插件市场': 'soft-center.asp'" "/koolshare/webs/tomato.js"
		pc_insert "admin-upgrade.asp" "'软件中心': {" "/koolshare/webs/tomato.js"
		pc_insert "admin-upgrade.asp" "}," "/koolshare/webs/tomato.js"

		# run kscore at last step
		sh /$KSROOT/bin/kscore.sh
	fi
}

softcenter_install
