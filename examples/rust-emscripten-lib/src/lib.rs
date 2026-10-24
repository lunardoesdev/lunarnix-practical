#![no_std]
#![no_main]

use core::ffi::{c_char, c_int, c_uint};
use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

extern "C" {
    fn printf(fmt: *const c_char, ...) -> c_int;
    fn zlibVersion() -> *const c_char;
    fn crc32(crc: c_uint, buf: *const u8, len: c_uint) -> c_uint;
}

#[no_mangle]
pub extern "C" fn main() -> c_int {
    let text = b"lunarnix rust + emscripten + zlib";
    let crc = unsafe { crc32(0, text.as_ptr(), text.len() as c_uint) };
    let fmt = b"zlib=%s rust_crc32=%u\n\0";

    unsafe {
        printf(fmt.as_ptr() as *const c_char, zlibVersion(), crc);
    }

    0
}
