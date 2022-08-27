#!/usr/bin/env zsh
FILENAME="CodeService"

function install_tools_if_needed() {
  if ! command -v "pip" &> /dev/null; then
    echo "pip not found. Install pip first."
    exit 1
  fi

  if ! command -v "when-changed" &> /dev/null; then
    pip install when-changed
  fi
}

function print_usage() {
  echo "Usage: ${ZSH_ARGZERO:t} [run|listen]"
}

function build() {
  echo "Building..."
  pushd build
  cmake --build . -j 4
  popd
}

function process_failed_test() {
  local line="$@"
  local file=$(echo "$line" | sed -E "s/^test format\ ([^\ ]*).*/\1/g")

  if [[ "$file" == "stability" ]]; then
    local file=$(echo "$line" | sed -E "s/^test format stability\ ([^\ ]*).*/\1/g")
    echo "Stability failed for: $file"
    return
  fi

  echo "Test failed for: $file"
  echo "------"
  CodeFormat format -f "Test/test_script/format_text/wait_format/$file" -c "Test/test_script/format_text/wait_format/.editorconfig"
  echo "------"
}

function process_failed_option_test() {
  local line="$@"
  local file=$(echo "$line" | sed -E "s/^test format\ ([^\ ]*).*/\1/g")

  if [[ "$file" == "stability" ]]; then
    local file=$(echo "$line" | sed -E "s/^test format stability\ ([^\ ]*).*/\1/g")
    echo "Stability failed for: $file"
    return
  fi

  echo "Test failed for: $file"
  echo "[*.lua]" > /tmp/test-config
  cat Test/test_script/format_text/wait_format_by_option/.editorconfig | grep "$file" -A1 | grep -v "$file" >> /tmp/test-config

  echo "------"
  CodeFormat format -f "Test/test_script/format_text/wait_format_by_option/$file" -c /tmp/test-config > /tmp/test-1
  cat /tmp/test-1
  echo "------"
  diff /tmp/test-1 "Test/test_script/format_text/wait_format_by_option_should_be/$file"
}

function test() {
  local test_dir="Test/test_script/format_text"

  echo
  echo "Testing regression..."
  CodeFormatTest CheckFormatResult -w $test_dir/wait_format -f $test_dir/wait_format_should_be | grep --line-buffered false | while read line; do
    process_failed_test "$line"
  done

  echo
  echo "Testing options..."
  CodeFormatTest CheckFormatResultByOption -w $test_dir/wait_format_by_option -f $test_dir/wait_format_by_option_should_be | grep --line-buffered -v "\-false" | grep --line-buffered false | while read line; do
    process_failed_option_test "$line"
  done
  #CodeFormat format -f ~/test.lua -c ~/lua.template.editorconfig

  echo "Done."
  echo
}

function listen() {
  echo "Listening for changes in $FILENAME..."
  when-changed -1 -r "$FILENAME" -c "echo 'Change detected...' && ./test.zsh" 
}

function run() {
  case "$@" in
    --help)
      print_usage
      exit 0
      ;;
    listen)
      build
      test
      listen
      ;;
    *)
      build
      test
      ;;
  esac
}

install_tools_if_needed
run "$@"

