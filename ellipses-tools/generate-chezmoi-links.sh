#!/bin/bash

set -e

CHEZMOI=$(chezmoi source-path)
real_ellipses=".ellipses"
abs_dotted_ellipses="$(chezmoi source-path "$HOME/$real_ellipses")"
dotted_ellipses="$(realpath --relative-to="$CHEZMOI" "$abs_dotted_ellipses")"

rm -fv $(fgrep -R -l --include "symlink_*.tmpl" "$dotted_ellipses" "$CHEZMOI") \
    $(fgrep -R -l --include "symlink_*" "/$real_ellipses/" "$CHEZMOI")

b_basename() {
    echo "${1##*/}"
}

b_dirname() {
    echo "${1%/*}"
}

get_real_name() {
    basename="$(b_basename "$1")"

    if [[ "$basename" =~ ^([a-z]+_)?([a-z]+_)?dot_(.*) ]]; then
        basename=".${BASH_REMATCH[3]}"
    elif [[ "$basename" =~ ^([a-z]+_)?([a-z]+_)?(.*) ]]; then
        basename="${BASH_REMATCH[3]}"
    fi

    echo "${basename%.tmpl}"
}

make_link() {
    tgt="${1//\/\//\/}"
    lnk="$2"
    path="${3//\/\//\/}"
    lnk_dir=$4

    [[ "${lnk:0:1}" == '.' ]] \
        && lnk="dot_${lnk#.}"

    lnk="$lnk_dir/symlink_$lnk"

    [ -z "$ELLIPSES_SILENT" ] && \
        echo "Linking $(chezmoi execute-template "$tgt") -> $path ($lnk)"

    if [[ "$tgt" == *"{{"*"}}"* ]]; then
        lnk="$lnk.tmpl"
    fi

    echo "$tgt" > "$CHEZMOI/$lnk"
}

generate_link() {
    local sf="$1"
    local pkg="$2"
    local fullpkg="$3"
    local tgt path rel

    bf=$(b_basename "$f")
    df=$(b_dirname "$f")
    name=$(get_real_name "$bf")
    e_rel_path="$real_ellipses/$fullpkg/$name"
    e_abs_path=$HOME/$e_rel_path
    rel_path="$(realpath --relative-to="$CHEZMOI/$dotted_ellipses/$pkg" "$df")"

    if ! [ -d "$CHEZMOI/$rel_path" ]; then
        echo "Path $CHEZMOI/$rel_path does not exist"
        echo "Ensure you added it and with correct permissions"
        echo "BUt absolute exists $(b_dirname $e_abs_path) ?"
        exit 1
    fi

    if [[ "$name" == ".ellipses_linkdirs" ]]; then
        return
    fi

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

    make_link "$tgt" "$name" "$path" "$rel_path"
}

handle_autolinks() {
    local dir=$1
    local fullpkg=$2

    local autolinks="$(cat "$dir/.ellipses-autolinks")"
    local rel_autolinks_dir="$real_ellipses/$autolinks"
    local abs_autolinks_dir="$HOME/$rel_autolinks_dir"
    local czm_autolinks_dir="$(chezmoi source-path "$abs_autolinks_dir")"
    local e_rel_path=$real_ellipses/$fullpkg/$subdir

    if [ -z "$czm_autolinks_dir" ]; then
        echo "Linkdir pointing to not-existent dir: $abs_autolinks_dir"
        exit 1
    fi

    # Using relative path to config
    # target_dir=$(realpath --relative-to="$autolinks_dir" "$el_path")

    # for al in "$dir"/*; do
    #     local rl=$(get_real_name "$al")
    #     local t="$target_dir/$rl"
    #     local l="$czm_autolinks_dir/symlink_$rl"

    #     [ -z "$ELLIPSES_SILENT" ] && \
    #         echo "Linking "$t" -> $l"

    #     echo "$t" > "$l"
    # done

    target_dir=$(realpath --relative-to="$CHEZMOI" "$czm_autolinks_dir")

    for al in "$dir"/*; do
        if [[ "$al" == symlink_* ]]; then
            continue
        fi

        local rl=$(get_real_name "$al")

        tgt="{{ .chezmoi.homedir }}/$e_rel_path/$rl"
        make_link "$tgt" "$rl" "$rel_autolinks_dir/$rl" "$target_dir"
    done
}

visit_directory() {
    dir="$1"
    bdir="$(b_basename "$dir")"
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

    for f in "$dir"/*; do
        if [ -L "$f" ]; then
            continue
        elif [ -d "$f" ]; then
            local current_dir=$f
            subdir="$(get_real_name "$(b_basename "$current_dir")")"

            if [ -f "$current_dir/.ellipses-ignore" ] ||
               [ -f "$HOME/$real_ellipses/$fullpkg/$subdir/.ellipses-ignore" ]; then
                continue
            fi

            if [ -d "$HOME/$allsubs/$subdir" ]; then
                if [ -L "$HOME/$allsubs/$subdir" ]; then
                    continue
                fi
                presubs=$allsubs
                allsubs+="$subdir/"
                predir=$current_dir

                visit_directory "$current_dir"

                allsubs=$presubs
                current_dir=$predir
            else
                generate_link "$current_dir" "$current_pkg" "$fullpkg"
            fi

            if [ -f "$current_dir/.ellipses-autolinks" ]; then
                handle_autolinks "$current_dir" "$fullpkg"
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
