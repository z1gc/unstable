EAPI="8"

inherit unstable

SLOT="0"
KEYWORDS="amd64"
S="${WORKDIR}"

# Language servers here as well:
# TODO: Split clang? And other wrappers?
DEPEND="
	app-editors/helix
	aptenodytes-forsteri/clang
	dev-python/python-lsp-server
	dev-util/bash-language-server
	dev-go/gopls
	dev-util/lua-language-server
	sys-devel/ra-multiplex
"
RDEPEND="${DEPEND}"

src_install() {
	insinto "/etc/helix"
	doins -r "${FILESDIR}/etc/." || die

	# Some custom wrappers:
	exeinto "/usr/local/bin"
	doexe -r "${FILESDIR}/bin/." || die
}
