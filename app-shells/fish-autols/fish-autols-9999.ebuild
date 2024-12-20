EAPI="8"

inherit git-r3

SLOT="0"
KEYWORDS="~amd64"
LICENSE="MIT"

DEPEND="app-shells/fish"
RDEPEND="${DEPEND}"

EGIT_REPO_URI="https://github.com/kpbaks/autols.fish.git"

src_install() {
	insinto "/etc/fish"
	doins -r "completions" "conf.d" "functions"
}
