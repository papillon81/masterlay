# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CHROMIUM_LANGS="cs de en-US es fr it ja pt-BR pt-PT ru tr uk zh-CN zh-TW"
inherit chromium-2 unpacker pax-utils xdg-utils desktop wrapper

RESTRICT="bindist strip"

MY_PV="${PV/_p/-}"
CHROMIUM_PV="103.0.5060.134"

DESCRIPTION="The web browser from Yandex"
HOMEPAGE="https://browser.yandex.ru/beta/"
LICENSE="Yandex-EULA"
SLOT="0"
SRC_URI="
	https://repo.yandex.ru/yandex-browser/deb/pool/main/y/yandex-browser-beta/yandex-browser-stable_${MY_PV}-1_amd64.deb -> ${P}.deb
	https://mirror.yandex.ru/ubuntu/pool/universe/c/chromium-browser/chromium-codecs-ffmpeg-extra_${CHROMIUM_PV}-0ubuntu0.18.04.1_amd64.deb
"
KEYWORDS="~amd64"

RDEPEND="
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	>=dev-libs/openssl-1.0.1:0
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/freetype
	net-misc/curl
	net-print/cups
	sys-apps/dbus
	sys-libs/libcap
	virtual/libudev
	x11-libs/cairo
	x11-libs/gdk-pixbuf
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXScrnSaver
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXtst
	x11-libs/pango[X]
	x11-misc/xdg-utils
"
DEPEND="
	>=dev-util/patchelf-0.9
	!!www-client/yandex-browser-beta
"

QA_PREBUILT="*"
S=${WORKDIR}
YANDEX_HOME="opt/yandex/browser"

pkg_setup() {
	chromium_suid_sandbox_check_kernel_config
}

src_unpack() {
	for a in ${A}; do
		echo "$a"
		unpack_deb ${a}
	done
}

src_prepare() {
	rm usr/bin/${PN} || die

	rm -r etc || die

	rm -r "${YANDEX_HOME}/cron" || die
	rm -r usr/share/man/man1/yandex-browser.1.gz

	gunzip usr/share/doc/${PN}/changelog.gz || die
	gunzip usr/share/man/man1/${PN}.1.gz || die

	mv usr/share/doc/${PN} usr/share/doc/${PF} || die

	pushd "${YANDEX_HOME}/locales" > /dev/null || die
	chromium_remove_language_paks
	popd > /dev/null || die

	default

	sed -r \
		-e 's|\[(NewWindow)|\[X-\1|g' \
		-e 's|\[(NewIncognito)|\[X-\1|g' \
		-e 's|^TargetEnvironment|X-&|g' \
		-i usr/share/applications/yandex-browser.desktop || die

	patchelf --remove-rpath "${S}/${YANDEX_HOME}/yandex_browser-sandbox" || die "Failed to fix library rpath (yandex_browser-sandbox)"
	patchelf --remove-rpath "${S}/${YANDEX_HOME}/yandex_browser" || die "Failed to fix library rpath (yandex_browser)"
	patchelf --remove-rpath "${S}/${YANDEX_HOME}/find_ffmpeg" || die "Failed to fix library rpath (find_ffmpeg)"
	patchelf --remove-rpath "${S}/${YANDEX_HOME}/nacl_helper" || die "Failed to fix library rpath (nacl_helper)"
}

src_install() {
	strip usr/lib/chromium-browser/libffmpeg.so
	mv usr/lib/chromium-browser/libffmpeg.so ${YANDEX_HOME}
	mv * "${D}" || die
	dodir "/usr/$(get_libdir)/${PN}/lib"
	make_wrapper "${PN}" "./yandex-browser" "${EPREFIX}/${YANDEX_HOME}" "${EPREFIX}/usr/$(get_libdir)/${PN}/lib"

	# yandex_browser binary loads libudev.so.0 at runtime
	dosym "${EPREFIX}/usr/$(get_libdir)/libudev.so.0" "${EPREFIX}/usr/$(get_libdir)/${PN}/lib/libudev.so.0"

	keepdir "${EPREFIX}/${YANDEX_HOME}"
	for icon in "${D}/${YANDEX_HOME}/product_logo_"*.png; do
		size="${icon##*/product_logo_}"
		size=${size%.png}
		dodir "/usr/share/icons/hicolor/${size}x${size}/apps"
		newicon -s "${size}" "$icon" "yandex-browser-beta.png"
	done

	fowners root:root "${EPREFIX}/${YANDEX_HOME}/yandex_browser-sandbox"
	fperms 4711 "${EPREFIX}/${YANDEX_HOME}/yandex_browser-sandbox"
	pax-mark m "${ED}${YANDEX_HOME}/yandex_browser-sandbox"
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
