# exit immediately upon error
set -e

function make_zip() {
	local folder
	local "${@}"
	find "$folder"  # prints paths of all files to be zipped
	7z a -tzip -r "$folder.zip" $folder
}

get_git_date() {
	local folder
	local "${@}"
	pushd "$folder" > /dev/null
	git show -s --format=%ci HEAD | sed 's/\([0-9]\{4\}\)-\([0-9][0-9]\)-\([0-9][0-9]\).*/\1\2\3/'
	popd > /dev/null
}

get_git_hash() {
	local folder
	local "${@}"
	pushd "$folder" > /dev/null
	git show -s --format=%h HEAD
	popd > /dev/null
}

cflags_runtime() {
	local runtime
	local configuration
	local "${@}"
	echo -n "-$runtime" | tr '[:lower:]' '[:upper:]'
	case "$configuration" in
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

target_id() {
	local base
	local extra
	local visual_studio
	local linkage
	local runtime
	local configuration
	local platform
	local "${@}"
	echo -n "$base-$(get_git_date folder=$base)-$(get_git_hash folder=$base)" | tr '[:upper:]' '[:lower:]'
	[[ !  -z  $extra  ]] && echo -n "-${extra}" | tr '[:upper:]' '[:lower:]'
	echo -n "-$visual_studio-$linkage-$runtime-$configuration-$platform" | tr '[:upper:]' '[:lower:]'
}

x264_options_linkage() {
	local linkage
	local "${@}"
	case "$linkage" in
		shared)
			echo " --enable-shared"
			;;
		static)
			echo " --enable-static"
			;;
		*)
			return 1
	esac
}

x264_options() {
	local prefix
	local runtime
	local configuration
	local "${@}"
	echo -n " --prefix=$prefix"
	echo -n " $(x264_options_linkage linkage=$linkage)"
	echo -n " --extra-cflags=$(cflags_runtime runtime=$runtime configuration=$configuration)"
}

function build_x264() {
	local prefix
	local runtime
	local configuration
	local "${@}"
	pushd x264
	# use latest config.guess to ensure that we can detect msys2
	curl "http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD" > config.guess
	# hotpatch configure script so we get the right compiler, compiler_style, and compiler flags
	sed -i 's/host_os = mingw/host_os = msys/' configure
	CC=cl ./configure $(x264_options prefix=$prefix runtime=$runtime configuration=$configuration) || (tail -30 config.log && exit 1)
	make
	make install
	# rename import libraries
	if [ "$linkage" = "shared" ]
	then
		pushd "$prefix/lib/"
		for file in *.dll.lib; do mv "$file" "${file/.dll.lib/.lib}"; done
		popd
	fi
	# delete pkgconfig files (not useful for msvc)
	rm -rf "$prefix/lib/pkgconfig"
	popd
}

function make_all() {
	local visual_studio
	local linkage
	local runtime
	local configuration
	local platform
	local "${@}"
	# ensure link.exe is the one from msvc
	mv /usr/bin/link /usr/bin/link1
	which link
	# ensure cl.exe can be called
	which cl
	cl
	local x264_folder=$(target_id base=x264 extra="GPL2" visual_studio="$visual_studio" linkage="static" runtime="$runtime" configuration="$configuration" platform="$platform")
	local x264_prefix=$(readlink -f $x264_folder)
	build_x264 prefix=$x264_prefix runtime=$runtime configuration=$configuration
	make_zip folder=$x264_folder
	mv /usr/bin/link1 /usr/bin/link
}

get_appveyor_visual_studio() {
	case "$APPVEYOR_BUILD_WORKER_IMAGE" in
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

set -xe
# bash starts in msys home folder, so first go to project folder
cd $(cygpath "$APPVEYOR_BUILD_FOLDER")
make_all \
	visual_studio=$(get_appveyor_visual_studio) \
	linkage="$LINKAGE" \
	runtime="$RUNTIME_LIBRARY" \
	configuration="$Configuration" \
	platform="$Platform"
