#!/bin/sh
# Export the Scribe Notebook tab into a git repo and optionally push.
#
#   notes-sync            export + commit + push
#   notes-sync export     write notebooks/ raw/ INDEX.md only
#   notes-sync push       commit + push whatever is already exported
#   notes-sync selfcheck  print whether this device can sync
#
# Cloud-only titles have no .nbk on disk. Open them once, then sync again.
# Config: /mnt/us/notes-sync.conf (see notes-sync.conf.example).

export PATH=/mnt/us/bin:/usr/bin:/bin
export HOME=/mnt/us
export GIT_EXEC_PATH=/mnt/us/opt/git/libexec/git-core
export GIT_TEMPLATE_DIR=/mnt/us/opt/git/share/git-core/templates
export GIT_SSH=/mnt/us/bin/git-ssh-scribe

NOTES=/mnt/us/notes
DEPLOY_KEY=/mnt/us/.ssh/id_scribe_notes
BRANCH=main
REMOTE=origin
REPO_TITLE=scribe-notes
PULL_HINT='git pull'

if [ -f /mnt/us/notes-sync.conf ]; then
  # shellcheck disable=SC1091
  . /mnt/us/notes-sync.conf
fi

export SCRIBE_DEPLOY_KEY="$DEPLOY_KEY"

NBK_ROOT=/mnt/us/.notebooks
DBSRC=/var/local/ksdk.content.db
LOG=/mnt/us/notes-sync.log
FBINK=/mnt/us/koreader/fbink
STAGING="$NOTES/.staging"
DB="$STAGING/ksdk.content.db"
CMD=${1:-all}

say() {
  echo "$1"
  if [ -x "$FBINK" ]; then
    "$FBINK" -q -pmM -y 4 "$1" || true
  fi
}

safe_name() {
  _s=$1
  [ -n "$_s" ] || _s=untitled
  echo "$_s" | tr '/\\:*?"<>|' '________' | sed 's/^ *//;s/ *$//'
}

json_esc() {
  echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

node_path() {
  _id=$1
  _acc=
  _n=0
  while [ -n "$_id" ] && [ "$_id" != root ] && [ "$_n" -lt 8 ]; do
    _title=$(sqlite3 "$DB" "SELECT title_collation FROM Nodes WHERE uuid='$_id';")
    _name=$(safe_name "$_title")
    if [ -z "$_acc" ]; then
      _acc=$_name
    else
      _acc="$_name/$_acc"
    fi
    _id=$(sqlite3 "$DB" "SELECT source_uuid FROM NodeRelations WHERE target_uuid='$_id' LIMIT 1;")
    _n=$((_n + 1))
  done
  echo "$_acc"
}

flush_local() {
  for _d in "$NBK_ROOT"/*; do
    [ -d "$_d" ] || continue
    _id=$(basename "$_d")
    case "$_id" in
      clipboard|page_cache|thumbnails|.backups) continue ;;
    esac
    lipc-set-prop com.lab126.notebookappmanager SaveAndSync "{\"notebookId\":\"$_id\"}" 2>/dev/null || true
  done
  sleep 1
}

export_library() {
  rm -rf "$STAGING"
  mkdir -p "$STAGING/notebooks" "$STAGING/raw"

  if [ ! -f "$DBSRC" ]; then
    echo "missing $DBSRC"
    return 1
  fi
  sqlite3 "$DBSRC" ".backup '$DB'"

  {
    echo "# $REPO_TITLE"
    echo
    echo "Exported $(date -u +%Y-%m-%dT%H:%MZ) from this device."
    echo
    echo "Close the notebook, tap **Notes Sync** (Wi-Fi on)."
    echo "\`MISSING\` = ink is not on disk. Open that notebook once, then sync again."
    echo
  } >"$STAGING/INDEX.md"
  printf 'uuid\ttype\ttitle\tpath\tlocal\tpages\ttemplate\n' >"$STAGING/library.tsv"

  local_n=0
  miss_n=0

  sqlite3 "$DB" "SELECT uuid FROM Nodes WHERE node_type='FOLDER';" | while read -r id; do
    [ -n "$id" ] || continue
    p=$(node_path "$id")
    [ -n "$p" ] || continue
    mkdir -p "$STAGING/notebooks/$p"
  done

  sqlite3 "$DB" "SELECT uuid FROM Nodes WHERE node_type='STANDALONE_NOTEBOOK';" >"$STAGING/ids.txt"
  while read -r id; do
    [ -n "$id" ] || continue
    title=$(sqlite3 "$DB" "SELECT title_collation FROM Nodes WHERE uuid='$id';")
    extra=$(sqlite3 "$DB" "SELECT additional_data FROM Nodes WHERE uuid='$id';")
    pages=$(echo "$extra" | sed -n 's/.*"total_page":\([-0-9]*\).*/\1/p')
    tmpl=$(echo "$extra" | sed -n 's/.*"notebook_template":"\([^"]*\)".*/\1/p')
    p=$(node_path "$id")
    [ -n "$p" ] || p=$(safe_name "$title")
    dest="$STAGING/notebooks/$p"
    if [ -e "$dest" ]; then
      dest="$dest-${id%%-*}"
      p="$p-${id%%-*}"
    fi
    mkdir -p "$dest"

    src="$NBK_ROOT/$id"
    thumb="$NBK_ROOT/thumbnails/$id.png"
    local=MISSING
    if [ -f "$src/nbk" ]; then
      local=local
      mkdir -p "$STAGING/raw/$id"
      cp "$src/nbk" "$STAGING/raw/$id/nbk"
      [ -f "$src/nbk-journal" ] && cp "$src/nbk-journal" "$STAGING/raw/$id/nbk-journal"
      [ -f "$src/actions.log" ] && cp "$src/actions.log" "$STAGING/raw/$id/actions.log"
      cp "$src/nbk" "$dest/notebook.nbk"
      local_n=$((local_n + 1))
    else
      miss_n=$((miss_n + 1))
    fi
    if [ -f "$thumb" ]; then
      cp "$thumb" "$dest/cover.png"
      mkdir -p "$STAGING/raw/$id"
      cp "$thumb" "$STAGING/raw/$id/cover.png"
    fi

    title_j=$(json_esc "$title")
    p_j=$(json_esc "$p")
    tmpl_j=$(json_esc "$tmpl")
    {
      echo "{"
      echo "  \"uuid\": \"$id\","
      echo "  \"title\": \"$title_j\","
      echo "  \"path\": \"$p_j\","
      echo "  \"pages\": \"$pages\","
      echo "  \"template\": \"$tmpl_j\","
      echo "  \"state\": \"$local\""
      echo "}"
    } >"$dest/meta.json"

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$id" STANDALONE_NOTEBOOK "$title" "$p" "$local" "$pages" "$tmpl" \
      >>"$STAGING/library.tsv"
    echo "- \`$p\` — **$local** (${pages:-?} pages)" >>"$STAGING/INDEX.md"
  done <"$STAGING/ids.txt"

  for d in "$NBK_ROOT"/*; do
    [ -d "$d" ] || continue
    id=$(basename "$d")
    case "$id" in
      *!!*!!notebook)
        mkdir -p "$STAGING/annotations/$id"
        [ -f "$d/nbk" ] && cp "$d/nbk" "$STAGING/annotations/$id/notebook.nbk"
        echo "- annotations \`$id\`" >>"$STAGING/INDEX.md"
        ;;
    esac
  done

  echo "$local_n" >"$STAGING/local.count"
  echo "$miss_n" >"$STAGING/miss.count"

  {
    echo "# $REPO_TITLE"
    echo
    echo "Native Kindle Scribe notebooks. Written on the Scribe, pushed from the Scribe."
    echo
    echo "On the device: close the notebook, then tap **Notes Sync** (Wi-Fi on)."
    echo "On a computer: \`$PULL_HINT\`."
    echo
    echo "See \`INDEX.md\` for the folder tree."
  } >"$STAGING/README.md"
}

publish_tree() {
  rm -rf "$NOTES/notebooks" "$NOTES/raw" "$NOTES/annotations"
  mv "$STAGING/notebooks" "$NOTES/notebooks"
  [ -d "$STAGING/raw" ] && mv "$STAGING/raw" "$NOTES/raw"
  [ -d "$STAGING/annotations" ] && mv "$STAGING/annotations" "$NOTES/annotations"
  mv "$STAGING/INDEX.md" "$NOTES/INDEX.md"
  mv "$STAGING/library.tsv" "$NOTES/library.tsv"
  mv "$STAGING/README.md" "$NOTES/README.md"
  rm -rf "$STAGING"
}

push_repo() {
  cd "$NOTES" || return 1
  if [ ! -d .git ]; then
    echo "no git repo in $NOTES"
    return 1
  fi
  git add -A
  if git diff --cached --quiet; then
    echo "nothing to commit"
  else
    git commit -m "scribe library: $(date -u +%Y-%m-%dT%H:%MZ)"
  fi
  git push -u "$REMOTE" "$BRANCH"
}

selfcheck() {
  echo "notes-sync selfcheck"
  ok=1
  for p in /usr/bin/sqlite3 /mnt/us/bin/git "$GIT_SSH" "$DBSRC" "$NBK_ROOT"; do
    if [ -e "$p" ]; then
      echo "  ok  $p"
    else
      echo "  MISS $p"
      ok=0
    fi
  done
  if [ -f "$DEPLOY_KEY" ]; then
    echo "  ok  deploy key $DEPLOY_KEY ($(wc -c <"$DEPLOY_KEY") bytes)"
  else
    echo "  MISS deploy key $DEPLOY_KEY"
    ok=0
  fi
  if command -v dbclient >/dev/null 2>&1 || [ -x /mnt/us/usbnetlite/bin/dropbearmulti ]; then
    echo "  ok  dbclient"
  else
    echo "  MISS dbclient"
    ok=0
  fi
  if [ -d "$NOTES/.git" ]; then
    echo "  ok  git repo $NOTES"
    (cd "$NOTES" && git remote -v)
  else
    echo "  MISS git repo $NOTES"
    ok=0
  fi
  n_local=0
  n_nb=0
  if [ -f "$DBSRC" ]; then
    n_nb=$(sqlite3 "$DBSRC" "SELECT COUNT(*) FROM Nodes WHERE node_type='STANDALONE_NOTEBOOK';")
  fi
  for d in "$NBK_ROOT"/*; do
    [ -f "$d/nbk" ] || continue
    id=$(basename "$d")
    case "$id" in
      *!!*!!notebook) continue ;;
    esac
    n_local=$((n_local + 1))
  done
  echo "  notebooks in library DB: $n_nb"
  echo "  standalone .nbk on disk: $n_local"
  [ "$ok" -eq 1 ]
}

case "$CMD" in
  selfcheck)
    selfcheck
    exit $?
    ;;
  export)
    {
      set -e
      echo "=== notes-sync export $(date) ==="
      say "exporting notebooks"
      flush_local
      export_library
      LOCAL_N=$(cat "$STAGING/local.count")
      MISS_N=$(cat "$STAGING/miss.count")
      publish_tree
      echo "OK local=$LOCAL_N missing=$MISS_N"
    } >>"$LOG" 2>&1
    RC=$?
    ;;
  push)
    {
      set -e
      echo "=== notes-sync push $(date) ==="
      say "pushing git"
      push_repo
      echo "OK push"
    } >>"$LOG" 2>&1
    RC=$?
    ;;
  all|"")
    {
      set -e
      echo "=== notes-sync $(date) ==="
      say "exporting notebooks"
      flush_local
      export_library
      LOCAL_N=$(cat "$STAGING/local.count")
      MISS_N=$(cat "$STAGING/miss.count")
      publish_tree
      say "pushing git"
      push_repo
      echo "OK local=$LOCAL_N missing=$MISS_N"
    } >>"$LOG" 2>&1
    RC=$?
    ;;
  *)
    echo "usage: notes-sync [all|export|push|selfcheck]" >&2
    exit 2
    ;;
esac

if [ "${RC:-0}" -ne 0 ]; then
  say "SYNC FAIL — see notes-sync.log"
  exit 1
fi

LAST=$(grep '^OK ' "$LOG" | tail -1)
say "${LAST:-OK}"
exit 0
