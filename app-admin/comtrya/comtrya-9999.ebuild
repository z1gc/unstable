EAPI=8

inherit cargo git-r3

DESCRIPTION="Configuration Management for Localhost / dotfiles"
HOMEPAGE="https://comtrya.dev"
EGIT_REPO_URI="https://github.com/comtrya/comtrya.git"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

src_unpack() {
	git-r3_src_unpack
	cargo_live_src_unpack
}

src_install() {
	cargo_src_install --path ./app
}
