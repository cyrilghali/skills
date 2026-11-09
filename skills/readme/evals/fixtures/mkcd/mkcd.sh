# Source this file, then: mkcd path/to/new/dir
mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}
