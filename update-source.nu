const upstream = "BrowserWorks/waterfox"
const tarball_url = "https://cdn1.waterfox.net/waterfox/releases/{tag_name}/Linux_x86_64/waterfox-{tag_name}.tar.bz2"

let token = $env.GITHUB_TOKEN? | default $env.GH_TOKEN?
if $token == null {
  error make { msg: "Provide a GH_TOKEN or GITHUB_TOKEN env" }
}

def get_sri_from_url [url: string]: nothing -> string {
  let path = nix-prefetch-url --unpack --print-path $url | split row "\n" | get 1
  nix hash path --type sha512 --sri $path
}

def main []: nothing -> nothing {
  let release = http get -H { Authorization: $"Bearer ($token)" } $"https://api.github.com/repos/($upstream)/releases/latest"
  let tarball_url = $release | format pattern $tarball_url
  let sri = get_sri_from_url $tarball_url
  
  do {
    let source = open source.json
    print $"version: ($source.version) -> ($release.tag_name)"
    print $"src.url: ($source.src.url) -> ($tarball_url)"
    print $"src.hash: ($source.src.hash) -> ($sri)"
  }

  {
    version: $release.tag_name
    src: {
      url: $tarball_url
      hash: $sri
    }
  } | to json | save -f source.json
}
