# -*- sh -*-

tweet_me() {
    echo "$@" | bti --host "${BTI_HOST}" --account "${BTI_ACCOUNT}" --password "${BTI_PASSWORD}" >/dev/null
}

pre_pkg_setup() {
    tweet_me "${CATEGORY}/${PF} merge starting"

    register_die_hook tinderbox_mask_pkg
    register_success_hook tinderbox_success
}

tinderbox_success() {
    tweet_me "${CATEGORY}/${PF} merge #succeded"
}

tinderbox_mask_pkg() {
    [[ ${EBUILD_PHASE} == test ]] && return 0
    tweet_me "${CATEGORY}/${PF} merge #failed"
    SANDBOX_ON=0 sed -i -e "\$a =${CATEGORY}/${PF}" /etc/portage/package.mask/currentrun
}

flameeyes_warning_if_file() {
    if [[ -s "${T}"/$1 ]]; then
	ewarn "Flameeyes QA Warning! $2"
	cat "${T}"/$1
	ewarn "Flameeyes QA Warning (end)! $2"
    fi
}

post_src_install() {
    # scanelf -q -F "#s%F" -R -s '-__(|l|f)xstat' "${D}" > "${T}"/flameeyes-scanelf-stat64.log
    # if [[ -s "${T}"/flameeyes-scanelf-stat64.log ]]; then
    # 	ewarn "Flameeyes QA Warning! Missing largefile support"
    # 	cat "${T}"/flameeyes-scanelf-stat64.log >/dev/stderr
    # fi

    rm -f "${T}"/flameeyes-scanelf-bundled.log
    for symbol in adler32 BZ2_decompress jpeg_mem_init XML_Parse avcodec_init png_get_libpng_ver lt_dlopen GC_stdout; do
	scanelf -qRs +$symbol "${D}" >> "${T}"/flameeyes-scanelf-bundled.log
    done
    flameeyes_warning_if_file flameeyes-scanelf-bundled.log "Possibly bundled libraries"

    rm -f "${T}"/flameeyes-scanelf-insecure.log
    for symbol in tmpnam tmpnam_r tempnam gets sigstack getpw getwd mktemp; do
	scanelf -qRs -$symbol "${D}" >> "${T}"/flameeyes-scanelf-insecure.log
    done
    flameeyes_warning_if_file flameeyes-scanelf-insecure.log "Insecure functions used"

    find "${D}" \
	\( -name '._*' -fprintf "${T}"/flameeyes-osx-forkfile.log "%P\n" \) , \
	\( -perm /6000 -fprintf "${T}"/flameeyes-setXid-binaries.log "%#m %u:%g %P\n" \) , \
	\( \( -path "${D}"usr/man/\* -or -path "${D}"usr/info/\* -or \
	-path "${D}"usr/X11R6/\* -or -path "${D}"usr/doc/\* -or \
	-path "${D}"usr/locale/\* -or -path "${D}"usr/lib/perl5/site_perl/\* -or \
	-path "${D}"usr/local/\* \
	\) -fprintf "${T}"/flameeyes-invalid-directory.log "/%P\n" \) , \
	\( -path "${D}"usr/share/doc/\* -type d -prune -not \( -name "${PF}" -or -name 'KDE4' -or -name 'HTML' \) \
	   -fprintf "${T}"/flameeyes-invalid-directory.log "/%P\n" \) ,  \
	\( -path "${D}"usr/share/locale/\* -name '*.mo' \
	   -fprintf "${T}"/flameeyes-locales.log "/%P\n" \) , \
	\( \( -path "${D}"/usr/lib\*/python\*/site-packages/\* -or \
	      -path "${D}"/usr/lib\*/ruby/site-ruby/\* -or \
	      -path "${D}"/usr/lib\*/perl5/\* \) -name '*.la' \
	      -fprintf "${T}"/flameeyes-pointless-la.log "/%P\n" \)

    if [[ -d "${D}"/usr/share/locale ]] && ! [[ -s "${T}"/flameeyes-locales.log ]]; then
	eqawarn "No locales installed (bug #264114)"
    fi

    scanelf -R "${D}"/usr/share > "${T}"/flameeyes-share-elfs.log

    if has binchecks ${RESTRICT}; then
	scanelf -R "${D}" > "${T}"/flameeyes-elfs-bincheck.log
    fi

    flameeyes_warning_if_file flameeyes-invalid-directory.log "Invalid directories in image"
    flameeyes_warning_if_file flameeyes-osx-forkfile.log "OSX fork files found (._*)"
    flameeyes_warning_if_file flameeyes-setXid-binaries.log "setXid files found"
    flameeyes_warning_if_file flameeyes-share-elfs.log "ELF files in /usr/share"
    flameeyes_warning_if_file flameeyes-elfs-bincheck.log "ELF files in a binchecks-restricted package"
    flameeyes_warning_if_file flameeyes-pointless-la.log "Pointless libtool .la files found"

    lafilefixer "${D}"
}

make() {
    if [[ "${FUNCNAME[1]}" == "einstall" ]] ; then
	emake -j1 "$@"
    else
        eqawarn "/etc/portage/bashrc QA notice: 'make' called by ${FUNCNAME[1]}"
        emake "$@"
    fi
}
