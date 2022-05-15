function __nr_apply
	set -l out $argv[1]
	set -l man (nix-store -q -b man $out 2>&1)
	echo "Adding $out ..."
	
	if [ -d "$man/share/man" ]
		set -a MANPATH "$man/share/man"
	end
	
	if [ -d "$out/share/man" ]
		set -a MANPATH "$out/share/man"
	end
	
	set -a PATH "$out/bin"
	
	if [ -f "$out/nix-support/propagated-user-env-packages" ]
		for f in (cat "$out/nix-support/propagated-user-env-packages")
			__nr_apply $f
		end
	end
end
# Defined in /tmp/fish.OJ1yiT/nr.fish @ line 2
function :u
	if ! set -q __NR_OLD_PATH
		set -g __NR_OLD_PATH $PATH
		set -g __NR_OLD_MANPATH $MANPATH
	end

	if [ (count $argv) -eq 0 ]
		set -xg PATH $__NR_OLD_PATH
		set -xg MANPATH $__NR_OLD_MANPATH
	end

	for arg in $argv
    nix build -L $argv --no-link && set -l out (nix eval --raw $argv)
		__nr_apply $out
	end
end
