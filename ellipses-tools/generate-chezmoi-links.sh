#!/bin/bash

set -e

CHEZMOI=$(chezmoi source-path)
real_ellipses=".ellipses"
abs_dotted_ellipses="$(chezmoi source-path "$HOME/$real_ellipses")"
dotted_ellipses="$(realpath --relative-to="$CHEZMOI" "$abs_dotted_ellipses")"

rm -fv $(fgrep -R -l --include "symlink_*.tmpl" "$dotted_ellipses" "$CHEZMOI") \
    $(fgrep -R -l --include "symlink_*" "/$real_ellipses/" "$CHEZMOI")

get_real_name() {
    basename="$1"

    if [[ "$basename" =~ ^([a-z]+_)?([a-z]+_)?dot_(.*) ]]; then
        basename=".${BASH_REMATCH[3]}"
    elif [[ "$basename" =~ ^([a-z]+_)?([a-z]+_)?(.*) ]]; then
        basename="${BASH_REMATCH[3]}"
    fi

    echo "${basename%.tmpl}"
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
    e_abs_path=$HOME/$e_rel_path
    rel_path="$(realpath --relative-to="$CHEZMOI/$dotted_ellipses/$pkg" "$df")"

    if ! [ -d "$CHEZMOI/$rel_path" ]; then
        echo "Path $CHEZMOI/$rel_path does not exist"
        echo "Ensure you added it and with correct permissions"
        echo "BUt absolute exists $(dirname $e_abs_path) ?"
        exit 1
    fi

    if [[ "$name" == ".ellipses_linkdirs" ]]; then
        return
    fi

    lnk="$name"
    [[ "${lnk:0:1}" == '.' ]] && lnk="dot_${lnk#.}"
    lnk="$rel_path/symlink_$lnk"

    if [[ "$bf" == symlink_* ]] || [[ "$bf" == encrypted_* ]] ||
       [[ "$bf" == *.tmpl ]] ||
       ([ -d "$f" ] &&
        ! [ -f "$e_abs_path/.ellipses_linkdir" ] &&
        ! grep -qs '\b'"$name"'\b' "$real_ellipses/$pkg/.ellipses_linkdirs"); then
        path="$e_abs_path"
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

            if [ -f "$HOME/$real_ellipses/$fullpkg/$subdir/.ellipses-ignore" ]; then
                continue
            fi

            if [ -d "$HOME/$allsubs/$subdir" ]; then
                if [ -L "$HOME/$allsubs/$subdir" ]; then
                    continue
                fi
                presubs=$allsubs
                allsubs+="$subdir/"
                visit_directory "$f"
                allsubs=$presubs
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
    allsubs=
    visit_directory "$i"
done


## Manual links
echo "{{ .chezmoi.homedir }}/$real_ellipses/shells/.bash_history_{{ .chezmoi.hostname }}" \
    > "$CHEZMOI/symlink_dot_bash_history.tmpl"
echo "{{ .chezmoi.homedir }}/$real_ellipses/shells/.bash_history_eternal_{{ .chezmoi.hostname }}"\
    > "$CHEZMOI/symlink_dot_bash_history_eternal.tmpl"
