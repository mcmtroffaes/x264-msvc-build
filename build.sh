# exit immediately upon error
set -e

# FOLDER
function make_zip() {
	7z a -tzip -r "$1.zip" $1
}

# FOLDER
get_git_date() {
	pushd "$1" > /dev/null
	git show -s --format=%ci HEAD | sed 's/\([0-9]\{4\}\)-\([0-9][0-9]\)-\([0-9][0-9]\).*/\1\2\3/'
	popd > /dev/null
}

# FOLDER
get_git_hash() {
	pushd "$1" > /dev/null
	git show -s --format=%h HEAD
	popd > /dev/null
}

# VISUAL_STUDIO
toolset () {
	case "$1" in
		Visual\ Studio\ 2013)
			echo -n "v120"
			;;
		Visual\ Studio\ 2015)
			echo -n "v140"
			;;
		Visual\ Studio\ 2017)
			echo -n "v141"
			;;
		*)
			return 1
	esac
}

# RUNTIME_LIBRARY CONFIGURATION
cflags_runtime() {
	echo -n "-$1" | tr '[:lower:]' '[:upper:]'
	case "$2" in
		Release)
			echo ""
			;;
		Debug)
			echo "d"
			;;
		*)
			return 1
	esac
}

# BASE LICENSE VISUAL_STUDIO LINKAGE RUNTIME_LIBRARY CONFIGURATION PLATFORM
target_id () {
	local toolset_=$(toolset "$3")
	local date_=$(get_git_date "$1")
	local hash_=$(get_git_hash "$1")
	echo "$1-${date_}-${hash_}-$2-${toolset_}-$4-$5-$6-$7" | tr '[:upper:]' '[:lower:]'
}

# LINKAGE
x264_options_linkage() {
	case "$1" in
		shared)
			echo "--enable-shared"
			;;
		static)
			echo "--enable-static"
			;;
		*)
			return 1
	esac
}

# PREFIX LINKAGE RUNTIME_LIBRARY CONFIGURATION
x264_options () {
	echo -n " --prefix=$1"
	echo -n " $(x264_options_linkage $2)"
	echo -n " --extra-cflags=$(cflags_runtime $3 $4)"
}

# PREFIX LINKAGE RUNTIME_LIBRARY CONFIGURATION
function build_x264() {
	# find absolute path for prefix
	local abs1=$(readlink -f $1)

	# install license file
	mkdir -p "$abs1/share/doc/x264"
	cp "x264/COPYING" "$abs1/share/doc/x264/license.txt"

	pushd x264
	# we need some fixes to build x264 under msys2; see patches here:
	# https://mailman.videolan.org/pipermail/x264-devel/2017-May/012155.html
	# 1. use latest config.guess to ensure that we can detect msys2
	curl "http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD" > config.guess
	# 2. update configure script so we get the right compiler, compiler_style, and compiler flags
	sed -i 's/host_os = mingw/host_os = msys/' configure
	CC=cl ./configure $(x264_options $abs1 $2 $3 $4) || (tail -30 config.log && exit 1)
	make
	make install
	# rename import libraries
	if [ "$2" = "shared" ]
	then
		pushd "$abs1/lib/"
		for file in *.dll.lib; do mv "$file" "${file/.dll.lib/.lib}"; done
		popd
	fi
	popd
}

# PREFIX LICENSE LINKAGE RUNTIME_LIBRARY CONFIGURATION PLATFORM
function make_nuget() {
	if [ "${6,,}" = "x86" ]
	then
		local platform="Win32"
	else
		local platform="x64"
	fi
	local fullnuspec="x264.$2.${3^}.$4.$5.${6,,}.nuspec"
	cat x264.nuspec.in \
		| sed "s/@DATE@/$(get_git_date x264)/g" \
		| sed "s/@HASH@/$(get_git_hash x264)/g" \
		| sed "s/@PREFIX@/$1/g" \
		| sed "s/@LICENSE@/$2/g" \
		| sed "s/@LINKAGE@/${3^}/g" \
		| sed "s/@RUNTIME_LIBRARY@/$4/g" \
		| sed "s/@CONFIGURATION@/$5/g" \
		| sed "s/@PLATFORM@/$platform/g" \
		> $fullnuspec
	cat $fullnuspec  # for debugging
	nuget pack $fullnuspec
}

# VISUAL_STUDIO LINKAGE RUNTIME_LIBRARY CONFIGURATION PLATFORM
function make_all() {
	# ensure link.exe is the one from msvc
	mv /usr/bin/link /usr/bin/link1
	which link
	# ensure cl.exe can be called
	which cl
	cl
	# BASE LICENSE VISUAL_STUDIO LINKAGE RUNTIME_LIBRARY CONFIGURATION PLATFORM
	local x264_prefix=$(target_id "x264" "GPL2" "$1" "$2" "$3" "$4" "$5")
	# PREFIX LINKAGE RUNTIME_LIBRARY CONFIGURATION
	build_x264 "$x264_prefix" "$2" "$3" "$4"
	# FOLDER
	make_zip "$x264_prefix"
	# PREFIX LICENSE LINKAGE RUNTIME_LIBRARY CONFIGURATION PLATFORM
	make_nuget "$x264_prefix" "GPL2" "$2" "$3" "$4" "$5"
	mv /usr/bin/link1 /usr/bin/link
}

function appveyor_main() {
	# bash starts in msys home folder, so first go to project folder
	cd $(cygpath "$APPVEYOR_BUILD_FOLDER")
	make_all "$APPVEYOR_BUILD_WORKER_IMAGE" \
		"$LINKAGE" "$RUNTIME_LIBRARY" "$Configuration" "$Platform"
}

function local_main() {
	make_all "$LICENSE" "$VISUAL_STUDIO" \
		"$LINKAGE" "$RUNTIME_LIBRARY" "$CONFIGURATION" "$PLATFORM"
}

set -x
appveyor_main
