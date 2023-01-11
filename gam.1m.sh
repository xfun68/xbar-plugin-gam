#!/usr/bin/env zsh

#  <xbar.title>gam</xbar.title>
#  <xbar.version>v0.1</xbar.version>
#  <xbar.author>Xiaofeng WANG</xbar.author>
#  <xbar.author.github>xfun68</xbar.author.github>
#  <xbar.desc>GitHub Actions monitor.</xbar.desc>
#  <xbar.image>TODO</xbar.image>
#  <xbar.dependencies>zsh,homebrew,gh,jq</xbar.dependencies>
#  <xbar.abouturl>TODO</xbar.abouturl>

#  <xbar.var>string(NAME=":dancer:"): Name to be displayed on menu bar.</xbar.var>
#  <xbar.var>string(REPOS=""): Repo list separated by comma, e.g. 'owner-foo/repo-foo;owner-bar/repo-bar'.</xbar.var>
#  <xbar.var>string(GITHUB_TOKEN=""): Generate token from here: 'https://github.com/settings/tokens', and do not forget to do SSO.</xbar.var>

readonly BREW_PREFIX=$([[ -d '/opt/homebrew/bin' ]] && echo '/opt/homebrew/bin' || echo '/usr/local/bin')
readonly CMD_GH="${BREW_PREFIX}/gh"
readonly CMD_JQ="${BREW_PREFIX}/jq"

readonly SYMBOL_GREEN='🟢'
readonly SYMBOL_RED='🔴'
readonly SYMBOL_BLUE='🔵'
readonly SYMBOL_YELLOW='🟡'
readonly SYMBOL_ORANGE='🟠'
readonly SYMBOL_PURPLE='🟣'
readonly SYMBOL_BROWN='🟤'
readonly SYMBOL_WHITE='⚪️'
readonly SYMBOL_BLACK='⚫️'
readonly SYMBOL_INPROGRESS='⏳'
readonly SYMBOL_TIMED_OUT='⏰'
readonly SYMBOL_FAST_FORWARD='⏩'
readonly SYMBOL_CANCELLED='⨂'
readonly SYMBOL_PLAY_PAUSE='⏯'
readonly SYMBOL_UNKNOWN='❓'

readonly DEFAULT_MENU_FONT_COLOR='white'

function main() {
    local LATEST_RUNS=$(echo "${REPOS}" | tr ';' '\n' | gam_gh_workflow_latest_run)
    local FAILED_RUNS=$(echo ${LATEST_RUNS} | grep -E ':(failure|timed_out|stale):')
    local MENU_FONT_COLOR=$([[ "${FAILED_RUNS}" != '' ]] && echo 'red' || echo ${DEFAULT_MENU_FONT_COLOR})

    echo "${NAME} | color=${MENU_FONT_COLOR}"
    echo "---"

    if [[ "${LATEST_RUNS}" == '' ]]; then
        echo "Please config this plugin first. (xbar -> Open plugin...)"
        return
    fi

    # if [[ "${FAILED_RUNS}" != '' ]]; then
    #     FAILED_PIPELINES="$(echo "${FAILED_RUNS}" | cut -d' ' -f2-3 | cut -d'/' -f1)"
    #     gam_sys_notify "Failed Pipelines" "${FAILED_PIPELINES}"
    # fi

    echo "${LATEST_RUNS}" \
    | gam_highlight \
        "completed" "$SYMBOL_GREEN" \
        "success" "$SYMBOL_GREEN" \
        "failure" "$SYMBOL_RED" \
        "cancelled" "$SYMBOL_CANCELLED" \
        "queued" "$SYMBOL_BLUE" \
        "in_progress" "$SYMBOL_INPROGRESS" \
        "waiting" "$SYMBOL_BROWN" \
        "action_required" "$SYMBOL_PLAY_PAUSE" \
        "timed_out" "$SYMBOL_TIMED_OUT" \
        "skipped" "$SYMBOL_FAST_FORWARD" \
        "stale" "$SYMBOL_BLACK" \
        "no_runs" "$SYMBOL_WHITE" \
        "[^:].*" "$SYMBOL_UNKNOWN"
}

function gam_gh_workflow_latest_run() {
    local RUN=''
    cat | while read -r REPO REST; do
        RUN="$(GH_TOKEN=${GITHUB_TOKEN} ${CMD_GH} api "/repos/${REPO}/actions/runs?page=1&per_page=1" | ${CMD_JQ} -jr '.workflow_runs[] | ":", if .conclusion then .conclusion else .status end, ": ", .actor.login, " ", .repository.name, "/", .name, "| href=", .html_url, "\n"')"
        if [[ "${RUN}" != '' ]]; then
            echo "${RUN}"
        else
            echo ":no_runs: ${REPO}"
        fi
    done
}

function gam_highlight() {
  local result="$(cat)"

  while [[ $# -ge 2 ]]; do
      result=$(echo "$result" | sed -E "s/:($1):/$2 \1/g")
    shift 2
  done

  echo "$result"
}

function gam_sys_notify() {
    local notification_command="display notification \"$2\" with title \"$1\""
    osascript -e "$notification_command"
}

main

