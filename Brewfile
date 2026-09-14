tap "homebrew/bundle"
# terraform left homebrew-core with the BSL relicence and now lives only in the
# vendor tap. Homebrew 7 additionally gates third-party taps behind an explicit
# trust step, so a fresh machine needs:
#   brew trust --formula hashicorp/tap/terraform
tap "hashicorp/tap"
# PowerShell is a formula in the vendor tap, not a cask. `brew tap` validates
# every formula in a tap, and the untrusted powershell-preview makes that fail
# with "invalid syntax in tap" — so trust the tap, not the single formula:
#   brew trust powershell/tap
tap "powershell/tap"
brew "powershell/tap/powershell"
brew "gh"
brew "git"
brew "unbound"
brew "grep"
brew "jq"
brew "k9s"
brew "lsd"
brew "kubernetes-cli"
brew "kubectx"
brew "nmap"
brew "node"
brew "nvm"
brew "hashicorp/tap/terraform", link: false
brew "tree"
brew "wget"
brew "bat"
brew "tldr"
brew "curl"
brew "helm"
brew "unzip"
brew "bison"
brew "dotnet"
brew "navi"
brew "yq"
# coreutils: ai/claude-code/scripts/worktree-guard.sh wants GNU realpath -m;
# BSD realpath has no -m and the hook fails open without it.
brew "coreutils"
# azure-cli: .zshrc_osx sources its bash completion unconditionally.
brew "azure-cli"
# krew: .zshrc_osx puts $KREW_ROOT/bin on PATH.
brew "krew"
# rtk: ai/claude-code/settings.json wires `rtk hook claude` as a PreToolUse
# hook, so the Brewfile should install what that config depends on.
brew "rtk"
