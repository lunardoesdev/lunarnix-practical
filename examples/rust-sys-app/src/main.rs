#![no_std]
#![no_main]

use core::ffi::{c_int, c_uint};
use core::panic::PanicInfo;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

#[no_mangle]
pub extern "C" fn main() -> c_int {
    let text = b"lunarnix rust -sys + emscripten";
    unsafe { zlib_sys::crc32(0, text.as_ptr(), text.len() as c_uint) as c_int }
}
