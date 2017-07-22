        ;; compiler-generated code ends
        ;; footer.asm begins
        times 510 - ($-$$) db 0
        dw    0xaa55
