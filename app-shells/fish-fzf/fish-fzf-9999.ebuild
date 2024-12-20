EAPI="8"

inherit git-r3

SLOT="0"
KEYWORDS="~amd64"
LICENSE="MIT"

DEPEND="
	app-shells/fish
	app-shells/fzf
	sys-apps/bat
"
RDEPEND="${DEPEND}"

EGIT_REPO_URI="https://github.com/PatrickF1/fzf.fish.git"

src_install() {
	insinto "/etc/fish"
	doins -r "completions" "conf.d" "functions"
}
