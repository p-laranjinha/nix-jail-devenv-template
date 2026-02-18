# Template for a "nix develop" environment with sandboxing

I've been using nix development environments since I started using NixOS, and although I've found
them very useful, there are some things I've wanted but are missing:

- The ability to "forget" my system's packages, so I can be sure I've specified every dependency
  and file I need in a projects `flake.nix`.
- The ability to sandbox the environment so I can experiment with binaries that might not be safe.

## jail.nix

To accomplish this, I'll be using [alexdavid/jail.nix](https://git.sr.ht/~alexdavid/jail.nix) to
wrap packages in [bubblewrap](https://github.com/containers/bubblewrap) for sandboxing.

The way I'm using this doesn't sandbox my whole shell, because that would be too much work to make
things like IDEs or Neovim (and even zsh) work and keep my config. Instead, I'm sandboxing
`bash` by default so that I can run anything I find online through a bash script and have it
sandboxed, and expect myself to sandbox things like `python` and `node` when I need to use them.

> [!NOTE]
> Because Neovim uses my current bash and **fzf-lua** doesn't seem to work with a sandboxed bash,
> I've made it so it uses the non-sandboxed bash.

I've added functions to make it easier to add jailed packages and only specify additional
combinators when needed, `jailPackageBinaries` and `jailPackages`, with the difference between them
being that the first one jails every binary added by a package and adds them to $PATH, while the
second only does so for the main binary.

The jailed packages are prefixed on $PATH, and so they can overwrite pre-existing packages, like
`ls`. I'm not overwritting the most common packages by default because I don't think there's much
of a point, as shell builtins, like `cd`, can't be jailed anyways; and I can just run things I want
sandboxed though bash.

> [!WARNING]
> As has been explained above, try to run things you find online and that may be unsafe through a
> bash script, as it has been sandboxed; or through whatever sandboxed package they require, like
> `python` or `node`.

### Alternatives

I've also considered using a full VM for sandboxing but I found it came with the same drawbacks as
using **bubblewrap** on my whole shell, but if I wanted to,
[Mix92/nixos-shell](https://github.com/Mic92/nixos-shell) would be a good option. Additionally,
while the drawbacks are the same with **jail.nix**, they would probably be easier to solve, as it
just lauches a whole NixOS system in a QEMU VM, I likely could just copy-paste my system neovim/zsh
configuration; unlike with **jail.nix**. which would require adapting it to use in `mkShell`.

Another alternative that also uses **bubblewrap** is
[nixpak/nixpak](https://github.com/nixpak/nixpak), which seems to be more customizable and
therefore better for people familiar with **bubblewrap**, but less beginner-friendly.

## direnv

An additional tool that is useful for development environments is [direnv](https://direnv.net),
which allows for automatic instantiation of the environment when the directory is entered, and
automatic exiting of the environment when the directory is exited.

This tool can be further augmented with [nix-direnv](https://github.com/nix-community/nix-direnv)
and [direnv-instant](https://github.com/Mic92/direnv-instant).
