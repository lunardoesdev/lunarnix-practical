#![no_std]

use core::ffi::{c_char, c_uint};

extern "C" {
    pub fn zlibVersion() -> *const c_char;
    pub fn crc32(crc: c_uint, buf: *const u8, len: c_uint) -> c_uint;
}
