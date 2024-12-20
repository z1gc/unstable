# app-editors/helix/helix-24.07.ebuild: 34b8e21634306979edc98da0311270bf55aa17e9

# Copyright 2024-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cargo desktop shell-completion xdg git-r3

DESCRIPTION="A post-modern text editor"
HOMEPAGE="
	https://helix-editor.com/
	https://github.com/helix-editor/helix
"
EGIT_REPO_URI="https://github.com/z1gc/helix.git"
S="${WORKDIR}"
EGIT_CHECKOUT_DIR="${S}"
EGIT_SUBMODULES=()

LICENSE="MPL-2.0"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 BSD Boost-1.0 ISC MIT MPL-2.0 MPL-2.0 Unicode-DFS-2016
	ZLIB
"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+grammar"

BDEPEND="app-misc/yq"
RDEPEND="dev-vcs/git"

pkg_setup() {
	rust_pkg_setup

	QA_FLAGS_IGNORED="
		usr/bin/hx
		/usr/$(get_libdir)/helix/.*\.so
	"
	export HELIX_DEFAULT_RUNTIME="${EPREFIX}/usr/share/${PN}/runtime"
	use grammar || export HELIX_DISABLE_AUTO_GRAMMAR_BUILD=1
}

src_unpack() {
	# https://wiki.gentoo.org/wiki/Writing_Rust_ebuilds#Writing_live_ebuilds
	git-r3_src_unpack
	cargo_live_src_unpack

	use grammar || return

	tasks=0
	tmpdir="$(mktemp -d)"

	# Prepare the grammars, it will fetch a little while...
	while read -r url rev name; do
		# Some languages use the same repository with multiple grammars.
		local local_id="${CATEGORY}/${PN}/${SLOT%/*}"
		case "$name" in
			"php"|"php-only")
				local_id+="/$name"
			;;
		esac
		local local_ref="refs/git-r3/${local_id}/__main__"

		# The git-r3 will always make commit-id shallow clone a single, that will be way slower,
		#  as many git servers are now supported this clone way.
		# https://github.com/gentoo/gentoo/blob/4ea63d2846762b2387678b5e35a8e866d819d9e3/eclass/git-r3.eclass#L714
		# FIXME: We're depending on 'git-r3.elass' implementation now, maybe someday gentoo will fix it.
		# We're using '&' to fork subshells, it's CoW, so local variables are safe (maybe).
		(
			# Git-r3 using the $url as the final directory, we need to ensure that's locked:
			# The http:// protocol is kind of "compatible" with POSIX file, huh.
			export HOME="$tmpdir/$url"
			mkdir -p "$(dirname "$HOME")"
			while ! mkdir "$HOME"; do
				sleep 1
			done

			# The output will be messed up...
			local -x GIT_DIR
			_git-r3_set_gitdir "$url"
			if ! git rev-parse --quiet --verify "$rev^{commit}"; then
				git fetch "$url" --depth 1 "$rev"
				git update-ref --no-deref "$local_ref" "$rev" || die
			fi

			git-r3_checkout "$url" "${S}/runtime/grammars/sources/$name" "$local_id"
			rm -rf "$HOME"
		) &

		# For simplicity, wait a bulk:
		if ((++tasks % 32 == 0)); then
			wait
		fi
	done < <(tomlq -r '.grammar[] | [.source.git, .source.rev, .name] | @tsv' "${S}/languages.toml" || die)

	# Last wait before going next:
	wait

	# tmpfile is cleaned after merged (mktemp will place them to /var/tmp/portage/...)
}

src_install() {
	cargo_src_install --path helix-term

	insinto "/usr/$(get_libdir)/${PN}"
	use grammar && doins runtime/grammars/*.so
	rm -r runtime/grammars || die
	use grammar && dosym "../../../$(get_libdir)/${PN}" "${EPREFIX}/usr/share/${PN}/runtime/grammars"

	insinto /usr/share/helix
	doins -r runtime

	doicon -s 256x256 contrib/${PN}.png
	domenu contrib/Helix.desktop

	insinto /usr/share/metainfo
	doins contrib/Helix.appdata.xml

	newbashcomp contrib/completion/hx.bash hx
	newzshcomp contrib/completion/hx.zsh _hx
	dofishcomp contrib/completion/hx.fish

	DOCS=(
		README.md
		CHANGELOG.md
		docs/
	)
	HTML_DOCS=(
		book/
	)
	einstalldocs
}

pkg_postinst() {
	if ! use grammar ; then
		einfo "Grammars are not installed yet. To fetch them, run:"
		einfo ""
		einfo "  hx --grammar fetch && hx --grammar build"
	fi

	xdg_desktop_database_update
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
