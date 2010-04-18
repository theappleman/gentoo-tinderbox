# -*- sh -*-

dent_me() {
    echo "$@" | bti --host "${BTI_HOST}" --account "${BTI_ACCOUNT}" --password "${BTI_PASSWORD}" >/dev/null
}

pre_pkg_setup() {
    dent_me "${CATEGORY}/${PF} merge starting"

    register_die_hook tinderbox_mask_pkg
    register_success_hook tinderbox_success
}

tinderbox_stats() {
    if fgrep -q 'Called src_test' "${PORTAGE_LOG_FILE}"; then
	echo " tests failed"
    fi

    if fgrep -q 'Detected file collision' "${PORTAGE_LOG_FILE}"; then
	echo " #collisions"
    fi
}

tinderbox_success() {
    dent_me "${CATEGORY}/${PF} merge #succeded$(tinderbox_stats)"
}

tinderbox_mask_pkg() {
    [[ ${EBUILD_PHASE} == test ]] && return 0
    dent_me "${CATEGORY}/${PF} merge #failed$(tinderbox_stats)"
    SANDBOX_ON=0 sed -i -e "\$a =${CATEGORY}/${PF}" /etc/portage/package.mask/currentrun
}

tinderbox_if_file() {
    if [[ -s "${T}"/$2 ]]; then
	eqawarn "Tinderbox QA $1! $3"
	cat "${T}"/$2
	eqawarn "Tinderbox QA $1 (end)! $3"
    fi
}

post_src_install() {
    rm -f "${T}"/tinderbox-*.log

    # scanelf -q -F "#s%F" -R -s '-__(|l|f)xstat' "${D}" > "${T}"/tinderbox-scanelf-stat64.log
    # if [[ -s "${T}"/tinderbox-scanelf-stat64.log ]]; then
    # 	ewarn "Tinderbox QA Warning! Missing largefile support"
    # 	cat "${T}"/tinderbox-scanelf-stat64.log >/dev/stderr
    # fi

    for symbol in adler32 BZ2_decompress jpeg_mem_init XML_Parse avcodec_init png_get_libpng_ver lt_dlopen GC_stdout; do
	scanelf -qRs +$symbol "${D}" >> "${T}"/tinderbox-scanelf-bundled.log
    done

    for symbol in tmpnam tmpnam_r tempnam gets sigstack getpw getwd mktemp; do
	scanelf -qRs -$symbol "${D}" >> "${T}"/tinderbox-scanelf-insecure.log
    done

    scanelf -R "${D}"/usr/share > "${T}"/tinderbox-share-elfs.log

    if has binchecks ${RESTRICT}; then
	scanelf -R "${D}" > "${T}"/tinderbox-elfs-bincheck.log
    fi

    find "${D}" \
	\( -name '._*' -fprintf "${T}"/tinderbox-osx-forkfile.log "%P\n" \) , \
	\( -perm /6000 -fprintf "${T}"/tinderbox-setXid-binaries.log "%#m %u:%g %P\n" \) , \
	\( \( -path "${D}"usr/man/\* -or -path "${D}"usr/info/\* -or \
	      -path "${D}"usr/X11R6/\* -or \
	      -path "${D}"usr/locale/\* -or \
	      -path "${D}"usr/local/\* \
	   \) -fprintf "${T}"/tinderbox-invalid-directory.log "/%P\n" \) , \
	\( -path "${D}"usr/lib/perl5/site_perl/\* \
	   -fprintf "${T}"/tinderbox-site-perl.log "/%P\n" \) , \
	\( -path "${D}"usr/doc/\* -or \
	   \( -path "${D}"usr/share/doc/\* -type d \
              -prune -not \( -name "${PF}" -or -name 'KDE4' -or -name 'HTML' \) \
           \) \
	   -fprintf "${T}"/tinderbox-misplaced-doc.log "/%P\n" \) ,  \
	\( -path "${D}"usr/share/locale/\* -name '*.mo' \
	   -fprintf "${T}"/tinderbox-locales.log "/%P\n" \) , \
	\( \( -path "${D}"usr/lib\*/python\*/site-packages/\* -or \
	      -path "${D}"usr/lib\*/ruby\*/site_ruby/\* -or \
	      -path "${D}"usr/lib\*/perl5/\* -or \
	      -path "${D}"lib\*/security/\* \) -name '*.la' \
	      -fprintf "${T}"/tinderbox-pointless-la.log "/%P\n" \)

    if [[ -d "${D}"/usr/share/locale ]] && ! [[ -s "${T}"/tinderbox-locales.log ]]; then
	eqawarn "Tinderbox QA Warning: No locales installed (bug #264114)"
    fi

    tinderbox_if_file Warning tinderbox-scanelf-bundled.log "Possibly bundled libraries"
    tinderbox_if_file Warning tinderbox-invalid-directory.log "Invalid directories in image"
    tinderbox_if_file Warning tinderbox-osx-forkfile.log "OSX fork files found (._*)"
    tinderbox_if_file Warning tinderbox-share-elfs.log "ELF files in /usr/share"
    tinderbox_if_file Warning tinderbox-elfs-bincheck.log "ELF files in a binchecks-restricted package"
    tinderbox_if_file Warning tinderbox-pointless-la.log "Pointless libtool .la files found"
    tinderbox_if_file Warning tinderbox-site-perl.log "Perl files installed in site_dir"
    tinderbox_if_file Warning tinderbox-misplaced-doc.log "Misplaced documentation"

    tinderbox_if_file Notice tinderbox-scanelf-insecure.log "Insecure functions used"
    tinderbox_if_file Notice tinderbox-setXid-binaries.log "setXid files found"

    lafilefixer "${D}"
}

make() {
    if [[ "${FUNCNAME[1]}" == "einstall" ]] ; then
	emake -j1 "$@"
    else
        eqawarn "Tinderbox QA Notice: 'make' called by ${FUNCNAME[1]}"
        emake "$@"
    fi
}
