EAPI="8"

inherit git-r3 gnome2-utils

SLOT="0"
KEYWORDS="~amd64"
LICENSE="GPL-3"

DEPEND="
	gnome-base/gnome-light
"
RDEPEND="${DEPEND}"
BDEPEND="app-misc/jq"

# Not really a live one:
EGIT_REPO_URI="https://github.com/daniellandau/switcher.git"
EGIT_COMMIT="0469784d628eeabc2a946e2b56057357b7cac94e"

src_install() {
	# Check if GNOME version supported:
	$(jq '."shell-version" | contains(["45"])' ./metadata.json) || die

	insinto "/usr/share/glib-2.0/schemas"
	doins "schemas/org.gnome.shell.extensions.switcher.gschema.xml"

	# Guessing:
	insinto "/usr/share/gnome-shell/extensions/switcher@landau.fi"
	doins -r "metadata.json" \
					 "stylesheet.css" \
					 ./*.js \
					 "modes" \
					 "switcher-icon.svg" \
					 "switcher-icon.png"
}

pkg_preinst() {
	gnome2_schemas_savelist
}

pkg_postinst() {
	gnome2_schemas_update
}

pkg_postrm() {
	gnome2_schemas_update
}
