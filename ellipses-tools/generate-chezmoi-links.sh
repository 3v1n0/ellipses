#!/bin/bash

CHEZMOI=$(chezmoi source-path)
real_ellipses=".ellipses"
abs_dotted_ellipses="$(chezmoi source-path "$HOME/$real_ellipses")"
dotted_ellipses="$(realpath --relative-to="$CHEZMOI" "$abs_dotted_ellipses")"

rm -fv $(fgrep -R -l --include "symlink_*.tmpl" "$dotted_ellipses" "$CHEZMOI") \
    $(fgrep -R -l --include "symlink_*" "/$real_ellipses/" "$CHEZMOI")

is_dotted() {
    [[ "$1" =~ ^([a-z]+_)?([a-z]+_)?dot_(.*) ]]
    echo "${BASH_REMATCH[3]%.tmpl}"
}

get_real_name() {
    basename="$1"
    undotted_file="$(is_dotted "$basename")"

    if [ -n "$undotted_file" ]; then
        echo ".$undotted_file"
        return 1
    else
        echo "${basename%.tmpl}"
        return 0
    fi
}

generate_link() {
    local sf="$1"
    local pkg="$2"
    local fullpkg="$3"
    local tgt path rel

    bf=$(basename "$f")
    df=$(dirname "$f")
    rel_path="$(realpath --relative-to="$CHEZMOI/$dotted_ellipses/$pkg" "$df")"
    lnk="$rel_path/symlink_${bf#*private_}"
    lnk="${lnk%.tmpl}"
    name="$(get_real_name "$bf")"

    if [[ "$bf" == encrypted_* ]] || [[ "$bf" == *.tmpl ]] || [ -d "$f" ]; then
        rel=$real_ellipses/$fullpkg/$name
        echo "Name is $name, ($rel)"
        path=$HOME/$rel
        tgt="{{ .chezmoi.homedir }}/$rel"
    else
        rel=$(realpath --relative-to="$CHEZMOI" "$f")
        path=$CHEZMOI/$rel
        tgt="{{ .chezmoi.sourceDir }}/$rel"
    fi

    echo "Linking $(chezmoi execute-template "$tgt") -> $path ($lnk)"

    if [[ "$tgt" == *"{{"*"}}"* ]]; then
        echo "$tgt" > "$CHEZMOI/$lnk.tmpl"
    else
        echo "$tgt" > "$CHEZMOI/$lnk"
    fi
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
