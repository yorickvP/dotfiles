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
		set -l out (nix-instantiate --eval --json --expr '
let
  tryImport = f: with builtins; let v = import f; in if isFunction v && (any (a: a) (attrValues (functionArgs v))) then v {} else v;
  isImportable = path: with builtins; if pathExists "${path}/" then pathExists "${path}/default.nix" else pathExists "${path}";

  pathBits = with builtins; map ({ prefix, path }:
      if prefix == "" then
        let
          contents = readDir path;
          names = builtins.filter (a: contents.${a} == "directory" && isImportable "${path}/${a}") (attrNames contents);
        in
          foldl\' (prev: val: prev // { ${val} = tryImport "${path}/${val}"; }) {} names
      else
        if isImportable path then
          { ${prefix} = tryImport path; }
        else
          { }
  ) nixPath;

  out = builtins.foldl\' (old: new: old // new) {} pathBits;
in with out; builtins.toPath ('"$arg"').outPath' | jq -r .)
		[ -e $out ] || nix-store -r $out > /dev/null
		__nr_apply $out
	end
end
