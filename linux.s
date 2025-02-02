/*
    linux.s     WJ125

    * linux system call interface

    Copyright (c) 2025 Walter de Jong <walter@heiho.net>

    Permission is hereby granted, free of charge, to any person obtaining a copy of
    this software and associated documentation files (the "Software"), to deal in
    the Software without restriction, including without limitation the rights to
    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
    of the Software, and to permit persons to whom the Software is furnished to do
    so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

.global sys_openat
.global sys_close
.global sys_read
.global sys_write
.global sys_exit
.global lib_open_readonly

.equ SYS_openat, 56
.equ SYS_close, 57
.equ SYS_read, 63
.equ SYS_write, 64
.equ SYS_exit, 93

.equ AT_FDCWD, -100
.equ O_RDONLY, 0

.text

/*
    system function: sys_openat
    x0 is dirfd
    x1 is ASCIIZ filename
    x2 is flags

    Returns return code of openat syscall in x0
*/
.type sys_openat, @function
sys_openat:
    mov w8, SYS_openat
    svc #0
    ret


/*
    system function: sys_close
    x0 is file descriptor

    Returns return code of close syscall in x0
*/
.type sys_close, @function
sys_close:
    mov w8, SYS_close
    svc #0
    ret


/*
    system function: sys_read
    x0 is file descriptor
    x1 is address of buffer
    x2 is number of bytes to read

    Returns return code of read syscall in x0
*/
.type sys_read, @function
sys_read:
    mov w8, SYS_read
    svc #0
    ret


/*
    system function: sys_write
    x0 is file descriptor
    x1 is address of buffer
    x2 is number of bytes to write

    Returns return code of write syscall in x0
*/
.type sys_write, @function
sys_write:
    mov w8, SYS_write
    svc #0
    ret


/*
    system function: sys_exit
    x0 is exit code

    This function exits the process and does not return
*/
.type sys_exit, @function
sys_exit:
    mov w8, SYS_exit
    svc #0


/*
    lib function: lib_open_readonly
    x0 is filename

    Returns file descriptor or error code from sys_openat
*/
.type lib_open_readonly, @function
lib_open_readonly:
    mov x1, x0
    mov x0, AT_FDCWD
    mov x2, O_RDONLY
    b sys_openat


/* EOB */
