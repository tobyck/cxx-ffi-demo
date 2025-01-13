use cxx;

#[cxx::bridge]
mod ffi {
    extern "Rust" {
        fn rust_hello();
    }

    unsafe extern "C++" {
        include!("hello.hpp");

        fn cpp_hello();
    }
}

fn rust_hello() {
    ffi::cpp_hello();
    println!("Kia ora! - From Rust");
}
