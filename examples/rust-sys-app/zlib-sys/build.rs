use std::process::Command;

fn main() {
    let output = Command::new("pkg-config")
        .args(["--libs", "zlib"])
        .output()
        .expect("failed to run pkg-config");

    if !output.status.success() {
        panic!(
            "pkg-config --libs zlib failed: {}",
            String::from_utf8_lossy(&output.stderr)
        );
    }

    for flag in String::from_utf8_lossy(&output.stdout).split_whitespace() {
        if let Some(path) = flag.strip_prefix("-L") {
            println!("cargo:rustc-link-search=native={path}");
        } else if let Some(lib) = flag.strip_prefix("-l") {
            println!("cargo:rustc-link-lib={lib}");
        }
    }

    println!("cargo:rerun-if-changed=build.rs");
}
