#!/bin/bash

CHEZMOI=$(chezmoi source-path)
real_ellipses=".ellipses"
abs_dotted_ellipses="$(chezmoi source-path "$HOME/$real_ellipses")"
dotted_ellipses="$(realpath --relative-to="$CHEZMOI" "$abs_dotted_ellipses")"

rm -fv $(fgrep -R -l --include "symlink_*.tmpl" "$dotted_ellipses" "$CHEZMOI") \
    $(fgrep -R -l --include "symlink_*" "/$real_ellipses/" "$CHEZMOI")

is_dotted() {
    if [[ "$1" =~ ^([a-z]+_)?([a-z]+_)?dot_(.*) ]]; then
        echo "${BASH_REMATCH[3]%.tmpl}"
        return 0
    fi
    return 1
}

get_real_name() {
    basename="$1"
    undotted_file="$(is_dotted "$basename")"

    if [ -n "$undotted_file" ]; then
        echo ".$undotted_file"
        return 0
    else
        echo "${basename%.tmpl}"
        return 1
    fi
}

generate_link() {
    local sf="$1"
    local pkg="$2"
    local fullpkg="$3"
    local tgt path rel

    bf=$(basename "$f")
    df=$(dirname "$f")
    name=$(get_real_name "$bf")
    e_rel_path="$real_ellipses/$fullpkg/$name"
    rel_path="$(realpath --relative-to="$CHEZMOI/$dotted_ellipses/$pkg" "$df")"

    lnk="${bf#*_protected}"
    lnk="${bf#*symlink_}"
    lnk="$rel_path/symlink_$lnk"
    lnk="${lnk%.tmpl}"

    if [[ "$bf" == symlink_* ]] || [[ "$bf" == encrypted_* ]] ||
       [[ "$bf" == *.tmpl ]] || [ -d "$f" ]; then
        path=$HOME/$e_rel_path
        tgt="{{ .chezmoi.homedir }}/$e_rel_path"
    else
        rel=$(realpath --relative-to="$CHEZMOI" "$f")
        path=$CHEZMOI/$rel
        tgt="{{ .chezmoi.sourceDir }}/$rel"
    fi

    tgt="${tgt//\/\//\/}"
    path="${path//\/\//\/}"
    echo "Linking $(chezmoi execute-template "$tgt") -> $path ($lnk)"

    if [[ "$tgt" == *"{{"*"}}"* ]]; then
        lnk="$lnk.tmpl"
    fi

    echo "$tgt" > "$CHEZMOI/$lnk"
}

visit_directory() {
    dir="$1"
    bdir="$(basename "$dir")"
    pkg="$(get_real_name "$bdir")"

    if ! [ -d "$dir" ] || [[ "${pkg[1]}" == "." ]]; then
        echo "Ignoring path $i"
        return
    fi

    prevfull="$fullpkg"
    fullpkg+="$pkg/"

    if [ -z "$current_pkg" ]; then
        current_pkg="$bdir"
    fi

    for f in $dir/*; do
        if [ -L "$f" ]; then
            continue
        elif [ -d "$f" ]; then
            subdir="$(get_real_name "$(basename "$f")")"

            if [ -L "$HOME/$subdir" ]; then
                continue
            elif [ -d "$HOME/$subdir" ]; then
                visit_directory "$f"
            else
                generate_link "$f" "$current_pkg" "$fullpkg"
            fi
        else
            generate_link "$f" "$current_pkg" "$fullpkg"
        fi
    done

    fullpkg="$prevfull"
}


for i in "$CHEZMOI/$dotted_ellipses"/*; do
    current_pkg=
    fullpkg=
    visit_directory "$i"
done
