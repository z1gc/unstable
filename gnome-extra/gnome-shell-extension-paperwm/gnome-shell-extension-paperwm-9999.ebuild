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

EGIT_REPO_URI="https://github.com/paperwm/PaperWM.git"

src_install() {
	# Check if GNOME version supported:
	$(jq '."shell-version" | contains(["45"])' ./metadata.json) || die

	insinto "/usr/share/glib-2.0/schemas"
	doins "schemas/org.gnome.shell.extensions.paperwm.gschema.xml"

	# @see generate-extension-zip.sh
	insinto "/usr/share/gnome-shell/extensions/paperwm@paperwm.github.com"
	doins -r "metadata.json" \
					 "stylesheet.css" \
					 ./*.js \
					 "config/user.js" \
					 "config/user.css" \
					 ./*.ui \
					 "resources"
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
