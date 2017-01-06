# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="5"

PYTHON_COMPAT=( python2_7 )
PYTHON_REQ_USE="ncurses?"

inherit eutils distutils-r1 gnome2-utils

MY_P="Electrum-${PV}"
DESCRIPTION="User friendly Bitcoin client"
HOMEPAGE="https://electrum.org/"
SRC_URI="https://download.electrum.org/${PV}/${MY_P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
LINGUAS="ar_SA cs_CZ de_DE eo_UY fr_FR hy_AM it_IT ky_KG nb_NO no_NO pt_BR ro_RO sk_SK ta_IN vi_VN bg_BG da_DK el_GR es_ES hu_HU id_ID ja_JP lv_LV nl_NL pl_PL pt_PT ru_RU sl_SI th_TH zh_CN"

IUSE="cli cosign email greenaddress_it ncurses qrcode sync trustedcoin_com vkb"

for lingua in ${LINGUAS}; do
	IUSE+=" linguas_${lingua}"
done

RDEPEND="
	dev-python/slowaes[${PYTHON_USEDEP}]
	dev-python/ecdsa[${PYTHON_USEDEP}]
	dev-python/pbkdf2[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
	dev-python/qrcode[${PYTHON_USEDEP}]
	dev-libs/protobuf[python,${PYTHON_USEDEP}]
	virtual/python-dnspython[${PYTHON_USEDEP}]
	dev-python/jsonrpclib[${PYTHON_USEDEP}]
	dev-python/setuptools[${PYTHON_USEDEP}]
	dev-python/PyQt4[X,${PYTHON_USEDEP}]
"

S="${WORKDIR}/${MY_P}"

DOCS="RELEASE-NOTES"

src_prepare() {
	# Don't advise using PIP
	sed -i "s/On Linux, try 'sudo pip install zbar'/Re-emerge Electrum with the qrcode USE flag/" lib/qrscanner.py || die

	# Prevent icon from being installed in the wrong location
	sed -i '/icons/d' setup.py || die

	validate_desktop_entries

	# Remove unrequested localization files:
	for lang in ${LINGUAS}; do
		use "linguas_${lang}" && continue
		rm -r "lib/locale/${lang}" || die
	done

	local wordlist=
	for wordlist in  \
		$(usex linguas_ja_JP '' japanese) \
		$(usex linguas_pt_BR '' portuguese) \
		$(usex linguas_pt_PT '' portuguese) \
		$(usex linguas_es_ES '' spanish) \
		$(usex linguas_zh_CN '' chinese_simplified) \
	; do
		rm -f "lib/wordlist/${wordlist}.txt" || die
		sed -i "/${wordlist}\\.txt/d" lib/mnemonic.py || die
	done

	# Remove unrequested GUI implementations:
	rm -rf gui/kivy*
	local gui
	for gui in  \
		$(usex cli      '' stdio)  \
		$(usex ncurses  '' text )  \
	; do
		rm gui/"${gui}"* -r || die
	sed -i '/icons/d' setup.py || die
	done

	local plugin
	# btchipwallet requires python btchip module (and dev-python/pyusb)
	# trezor requires python trezorlib module
	# keepkey requires trezor
	for plugin in  \
		$(usex cosign        '' cosigner_pool   ) \
		hw_wallet \
		ledger \
		$(usex email         '' email_requests  ) \
		$(usex greenaddress_it '' greenaddress_instant)  \
		keepkey \
		$(usex sync          '' labels          )  \
		trezor  \
		$(usex trustedcoin_com '' trustedcoin   )  \
		$(usex vkb           '' virtualkeyboard )  \
	; do
		rm -r plugins/"${plugin}"* || die
		sed -i "/${plugin}/d" setup.py || die
	done

	distutils-r1_src_prepare
}

src_install() {
	doicon -s 128 icons/${PN}.png
	distutils-r1_src_install
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	gnome2_icon_cache_update
}

pkg_postrm() {
	gnome2_icon_cache_update
}
