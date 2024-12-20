EAPI=8

inherit cargo git-r3

DESCRIPTION="share one rust-analyzer server instance between multiple LSP clients to save resources"
HOMEPAGE="https://github.com/pr2502/ra-multiplex"
EGIT_REPO_URI="https://github.com/pr2502/ra-multiplex.git"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

src_unpack() {
	git-r3_src_unpack
	cargo_live_src_unpack
}
