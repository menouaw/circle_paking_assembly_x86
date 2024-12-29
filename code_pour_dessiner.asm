; Améliorations potentielles
;

; external functions from X11 library
extern    XOpenDisplay
extern    XDisplayName
extern    XCloseDisplay
extern    XCreateSimpleWindow
extern    XMapWindow
extern    XRootWindow
extern    XSelectInput
extern    XFlush
extern    XCreateGC
extern    XSetForeground
extern    XDrawLine
extern    XNextEvent
extern    XDrawArc

; external functions from stdio library (ld-linux-x86-64.so.2)
extern    printf
extern    exit

%define    StructureNotifyMask    131072
%define    KeyPressMask           1
%define    ButtonPressMask        4
%define    MapNotify              19
%define    KeyPress               2
%define    ButtonPress            4
%define    Expose                 12
%define    ConfigureNotify        22
%define    CreateNotify           16
%define    QWORD                  8
%define    DWORD                  4
%define    WORD                   2
%define    BYTE                   1

%define    BACKGROUND_COLOR       0xffc7e9
%define    WIDTH                  600
%define    HEIGHT                 600

%define    RAYON_CERCLE_EXTERNE  150

%define    RAYON_MAX             RAYON_CERCLE_EXTERNE/4

%define    NB_PRE_CIRCLES        250
%define    NB_POST_CIRCLES       100 ; /!\ Ne semble pas supporter au-delà de 150?

%define    NB_KIT_STEP           26

global    main

section .bss
display_name:    resq    1
screen:          resd    1
depth:           resd    1
connection:      resd    1
width:           resd    1
height:          resd    1
window:          resq    1
gc:              resq    1

i:               resw    1
color_counter:    resw   1

section .data
event:           times    24 dq 0

ext_circle_x:    dw 0
ext_circle_y:    dw 0
ext_circle_r:    dw 0

pre_circles_x:         times NB_PRE_CIRCLES dw 0
pre_circles_y:         times NB_PRE_CIRCLES dw 0
pre_circles_r:         times NB_PRE_CIRCLES dw 0
pre_circles_r_tampon:  times NB_PRE_CIRCLES dw 0

post_circles_x:        times NB_POST_CIRCLES dw 0
post_circles_y:        times NB_POST_CIRCLES dw 0
post_circles_r:        times NB_POST_CIRCLES dw 0
post_circles_r_tampon: times NB_POST_CIRCLES dw 0

dist_min:         dw 0
ind_closest_init: dw 0
ind_closest_tan:  dw 0

kit_colors:      times NB_KIT_STEP dd 0

bool_fin:        db 0    

fmt_debug:       db "Debug: %d", 10, 0
fmt_debug_x:     db "Debug: %x", 10, 0

fmt_init_circles: db "Cercle initial %d : x = %d, y = %d, r = %d", 10, 0
fmt_tan_circles:  db "Cercle tangent %d : x = %d, y = %d, r = %d", 10, 0

crlf:            db 10, 0

section .text
;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:
    ;###########################################################
    ; Mettez ici votre code qui devra sexécuter avant le dessin
    ;###########################################################
    ; Remplissage des couleurs du kit
    ; palier 1
    mov dword[kit_colors+0*DWORD], 0x0ebeff
    ; palier 2
    mov dword[kit_colors+1*DWORD], 0x18b9fc
    mov dword[kit_colors+2*DWORD], 0x21b4f9
    mov dword[kit_colors+3*DWORD], 0x2baff6
    mov dword[kit_colors+4*DWORD], 0x35aaf3
    mov dword[kit_colors+5*DWORD], 0x3ea5f0
    mov dword[kit_colors+6*DWORD], 0x48a0ed
    mov dword[kit_colors+7*DWORD], 0x519bea
    mov dword[kit_colors+8*DWORD], 0x5b96e7
    mov dword[kit_colors+9*DWORD], 0x6591e4
    mov dword[kit_colors+10*DWORD], 0x6e8ce1
    mov dword[kit_colors+11*DWORD], 0x7887de
    mov dword[kit_colors+12*DWORD], 0x8282db
    mov dword[kit_colors+13*DWORD], 0x8b7ed7
    mov dword[kit_colors+14*DWORD], 0x9579d4
    mov dword[kit_colors+15*DWORD], 0x9f74d1
    mov dword[kit_colors+16*DWORD], 0xa86fce
    mov dword[kit_colors+17*DWORD], 0xb26acb
    mov dword[kit_colors+18*DWORD], 0xbc65c8
    mov dword[kit_colors+19*DWORD], 0xc560c5
    mov dword[kit_colors+20*DWORD], 0xcf5bc2
    mov dword[kit_colors+21*DWORD], 0xd856bf
    mov dword[kit_colors+22*DWORD], 0xe251bc
    mov dword[kit_colors+23*DWORD], 0xec4cb9
    mov dword[kit_colors+24*DWORD], 0xf547b6
    mov dword[kit_colors+25*DWORD], 0xff42b3
    
    ;mov rdi, fmt_debug_x
    ;mov esi, dword[kit_colors+0*DWORD]
    ;mov rax, 0
    ;call printf

    ;###############################
    ; Code de création de la fenêtre
    ;###############################
    xor    rdi, rdi
    call   XOpenDisplay
    mov    qword[display_name], rax

    ; display_name structure
    ; screen = DefaultScreen(display_name);
    mov    rax, qword[display_name]
    mov    eax, dword[rax+0xe0]
    mov    dword[screen], eax

    mov    rdi, qword[display_name]
    mov    esi, dword[screen]
    call   XRootWindow
    mov    rbx, rax

    mov    rdi, qword[display_name]
    mov    rsi, rbx
    mov    rdx, 10
    mov    rcx, 10
    mov    r8, WIDTH
    mov    r9, HEIGHT
    push   BACKGROUND_COLOR
    push   0x00FF00
    push   1
    call   XCreateSimpleWindow
    add rsp, 24
    
    mov    qword[window], rax
    mov    rdi, qword[display_name]
    mov    rsi, qword[window]
    mov    rdx, 131077
    call   XSelectInput

    mov    rdi, qword[display_name]
    mov    rsi, qword[window]
    call   XMapWindow

    mov    rdi, qword[display_name]
    mov    rsi, qword[window]
    mov    rdx, 0
    mov    rcx, 0
    call   XCreateGC
    mov    qword[gc], rax

    mov    rdi, qword[display_name]
    mov    rsi, qword[gc]
    mov    rdx, 0x000000
    call   XSetForeground

boucle:                              ; boucle de gestion des évènements
    mov    rdi, qword[display_name]
    mov    rsi, event
    call   XNextEvent
    
    cmp    dword[event], KeyPress
    je     closeDisplay
    
    cmp byte[bool_fin], 1 ; vérifie si le programme a déjà généré les cercles
    je flush
    
    cmp    dword[event], ConfigureNotify
    je     dessin
    
    jmp    boucle

;#########################################
;#        DEBUT DE LA ZONE DE DESSIN     #
;#########################################
dessin:
    ; itère le programme jusqu'à l'arrêt
    mov    rdi, qword[display_name]
    mov    rsi, qword[gc]
    mov    edx, dword[kit_colors+1*DWORD]      ; Couleur du crayon ; deuxième palier
    call   XSetForeground

    ; ETAPE 3

    mov ax, WIDTH
    shr ax, 1 ; divison par 2 via décalage de bits vers la droite
    mov r10w, ax

    mov ax, HEIGHT
    shr ax, 1
    mov r11w, ax

    mov r12w, RAYON_CERCLE_EXTERNE

    mov cx, r12w
    mov word[ext_circle_r], r12w

    mov bx, r10w
    mov word[ext_circle_x], bx

    sub bx, cx
    movzx rcx, bx

    mov bx, r11w
    mov word[ext_circle_y], bx
    ; FIN ETAPE 3

    ; ETAPE 1
    mov    word[i], 0
    mov    word[color_counter], 0
boucle_cercles_initiaux:
    ; génère les cercles initiaux
    mov    r14w, word[i]
    mov    rdi, WIDTH
    call   random_number
    mov    r10w, ax

    mov    rdi, HEIGHT
    call   random_number
    mov    r11w, ax

    mov    rdi, RAYON_MAX
    call   random_number
    mov    r12w, ax

    mov    cx, r12w
    mov    word[pre_circles_r+r14*WORD], r12w
    mov    word[pre_circles_r_tampon+r14*WORD], r12w

    mov    bx, r10w
    mov    word[pre_circles_x+r14*WORD], bx

    sub    bx, cx
    movzx  rcx, bx

    mov    bx, r11w
    mov    word[pre_circles_y+r14*WORD], bx

boucle_verif_pre_dans_ext:
    ; vérifie que les cercles initiaux se trouvent dans le cercle externe
    movzx edi, word[pre_circles_x+r14*WORD]
    movzx esi, word[pre_circles_y+r14*WORD]
    movzx edx, word[ext_circle_x]
    movzx ecx, word[ext_circle_y]

    call points_gap

    mov r10, 1 ; x, y du cercle
    movzx r11, word[ext_circle_r]
    add r10, r11

    cmp rax, r10
    ja boucle_cercles_initiaux

    mov    r13, 0
boucle_verif_pre_restrictions:
    ; vérifie que les cercles initiaux ne se chevauchent pas et ne sont pas tangents
    cmp    r13, r14
    je     next_pre

    movzx  edi, word[pre_circles_x+r14*WORD]
    movzx  esi, word[pre_circles_y+r14*WORD]
    movzx  edx, word[pre_circles_x+r13*WORD]
    movzx  ecx, word[pre_circles_y+r13*WORD]

    call   points_gap

    movzx  r10, word[pre_circles_r+r14*WORD]
    movzx  r11, word[pre_circles_r+r13*WORD]
    add    r10, r11

    cmp    rax, r10
    jle    boucle_cercles_initiaux

next_pre:
    ; vérifications passées, affiche le cercle courant
    inc    r13
    cmp    r13, NB_PRE_CIRCLES
    jb     boucle_verif_pre_restrictions

generate_circle_step_one:
    mov    rdi, qword[display_name]
    mov    rsi, qword[window]
    mov    rdx, qword[gc]

    mov    cx, word[pre_circles_r_tampon+r14*WORD]
    mov    bx, word[pre_circles_x+r14*WORD]
    sub    bx, cx
    movzx  rcx, bx

    mov    bx, word[pre_circles_y+r14*WORD]
    mov    r15w, word[pre_circles_r_tampon+r14*WORD]
    sub    bx, r15w
    movzx  r8, bx
    movzx  r9, word[pre_circles_r_tampon+r14*WORD]
    shl    r9, 1
    mov    rax, 23040
    push   rax
    push   0
    push   r9

    call   XDrawArc
    add rsp, 24

pre_inner_arc:
    mov r15w, word[pre_circles_r_tampon+r14*WORD]
    cmp r15w, 0
    je boucle_affichage_pre

    mov ax, word[color_counter]
    mov bx, NB_KIT_STEP ; div ne prend pas de valeur fixe
    xor dx, dx
    div bx ; reste dans dx

    ;mov rdi, fmt_debug
    ;movzx rsi, dx
    ;mov rax, 0
    ;call printf

    movzx r15, dx

    mov rdi, qword[display_name]
    mov rsi, qword[gc]
    mov edx, dword[kit_colors+r15*DWORD]
    call XSetForeground

    dec word[pre_circles_r_tampon+r14*WORD]
    inc word[color_counter]
    jmp generate_circle_step_one

    ; FIN ETAPE 1

boucle_affichage_pre:
    ; affichage dans la sortie standard (non demandé)
    mov    rdi, fmt_init_circles
    movzx  rsi, r14b
    movzx  rdx, word[pre_circles_x+r14*WORD]
    movzx  rcx, word[pre_circles_y+r14*WORD]
    movzx  r8, word[pre_circles_r+r14*WORD]
    mov    rax, 0
    call   printf

boucle_incrementation_compteur_init:
    inc    word[i]
    cmp    word[i], NB_PRE_CIRCLES
    jb     boucle_cercles_initiaux

    mov rdi, crlf
    mov rax, 0
    call printf

    ; ETAPE 2
    mov word[i], 0
    mov word[color_counter], 0
boucle_cercles_tangents:
    ; génère les cercles tangents
    mov r14w, word[i]
    mov rdi, WIDTH
    call random_number
    mov r10w, ax ; stocke le x aléatoire dans r10w

    mov rdi, HEIGHT
    call random_number
    mov r11w, ax ; stocke le y aléatoire dans r11w

    ;mov rdi, RAYON_MAX
    ;call random_number
    mov r12w, 1 ; on place un point

    mov cx, r12w
    mov word[post_circles_r+r14*WORD], r12w

    mov bx, r10w
    mov word[post_circles_x+r14*WORD], bx
    mov bx, cx
    movzx rcx, bx
    
    mov bx, r11w
    mov word[post_circles_y+r14*WORD], bx
    
boucle_verif_post_dans_ext:
    ; vérifie que les cercles tangents se trouvent dans le cercle externe
    movzx edi, word[post_circles_x+r14*WORD]
    movzx esi, word[post_circles_y+r14*WORD]
    movzx edx, word[ext_circle_x]
    movzx ecx, word[ext_circle_y]
    
    call points_gap
    
    mov r10, 1 ; x, y du cercle (pathologique)
    movzx r11, word[ext_circle_r]
    add r10, r11
    
    cmp rax, r10
    ja boucle_cercles_tangents
    
mov r13, 0
boucle_verif_post_restrictions_init:
    ; vérifie que le cercle ne chevauche pas un cercle initial (mais permet la tangence)
    movzx edi, word[pre_circles_x+r13*WORD]
    movzx esi, word[pre_circles_y+r13*WORD]
    movzx edx, word[post_circles_x+r14*WORD]
    movzx ecx, word[post_circles_y+r14*WORD]
    
    call points_gap
    
    movzx r10, word[pre_circles_r+r13*WORD]
    movzx r11, word[post_circles_r+r14*WORD]
    add r10, r11
    
    cmp rax, r10
    jl boucle_cercles_tangents
    
next_post_init:
    inc r13
    cmp r13, NB_PRE_CIRCLES
    jb boucle_verif_post_restrictions_init
    
mov r13, 0 
boucle_verif_post_restrictions_tan:
    ; vérifie que le cercle ne chevauche pas un cercle tangent (mais permet la tangence)
    cmp r13, r14
    je next_post_tan
    
    movzx edi, word[post_circles_x+r13*WORD]
    movzx esi, word[post_circles_y+r13*WORD]
    movzx edx, word[post_circles_x+r14*WORD]
    movzx ecx, word[post_circles_y+r14*WORD]
    
    call points_gap
    
    movzx r10, word[post_circles_r+r13*WORD]
    movzx r11, word[post_circles_r+r14*WORD]
    add r10, r11
    
    cmp rax, r10
    jl boucle_cercles_tangents

next_post_tan:
    inc r13
    cmp r13, r14
    jb boucle_verif_post_restrictions_tan
    
boucle_cercle_proche:
    ; on cherche le cercle le plus proche
    mov word[dist_min], RAYON_MAX
    
    mov r13, 0
boucle_cp_init:
    ; parmi les cercles initiaux
    movzx edi, word[post_circles_x+r14*WORD]
    movzx esi, word[post_circles_y+r14*WORD]
    movzx edx, word[pre_circles_x+r13*WORD]
    movzx ecx, word[pre_circles_y+r13*WORD]
    
    call points_gap
    
    cmp ax, word[dist_min]
    ja next_cp_init
    
    mov word[dist_min], ax
    mov word[ind_closest_init], r13w
    
next_cp_init:
    inc r13
    cmp r13, NB_PRE_CIRCLES
    jb boucle_cp_init
    
    movzx r8, word[dist_min]
    mov r13, 0
boucle_cp_tan:
    cmp r13, r14
    je next_cp_tan
        
    movzx edi, word[post_circles_x+r14*WORD]
    movzx esi, word[post_circles_y+r14*WORD]
    movzx edx, word[post_circles_x+r13*WORD]
    movzx ecx, word[post_circles_y+r13*WORD]
        
    call points_gap
    
    cmp ax, word[dist_min]
    ja next_cp_tan
        
    mov word[dist_min], ax
    mov word[ind_closest_tan], r13w
        
next_cp_tan:
    inc r13
    cmp r13, NB_POST_CIRCLES
    jb boucle_cp_tan
    
    cmp word[dist_min], r8w
    
    ;mov rdi, fmt_debug
    ;movzx rsi, r8w
    ;mov rax, 0
    ;call printf
    ;mov rdi, fmt_debug
    ;movzx rsi, word[dist_min] 
    ;mov rax, 0
    ;call printf
    
    je case_cp_init
    jne case_cp_tan
    
case_cp_init:
    ; new_circle_r = dist_min - closest_circle_r
    mov ax, r8w
    mov r15w, word[ind_closest_init]
    sub ax, word[pre_circles_r+r15*WORD]
    cmp ax, 0 ; vérifie que le rayon est positif
    jle boucle_verif_post_restrictions_tan
    
    mov word[post_circles_r+r14*WORD], ax
    mov word[post_circles_r_tampon+r14*WORD], ax
    jmp entry_point_boucle_verif_post_restrictions_init_2
    
case_cp_tan:
    mov ax, r8w
    mov r15w, word[ind_closest_tan]
    sub ax, word[post_circles_r+r15*WORD]
    cmp ax, 0
    jle boucle_verif_post_restrictions_tan
    
    mov word[post_circles_r+r14*WORD], ax
    mov word[post_circles_r_tampon+r14*WORD], ax
    jmp entry_point_boucle_verif_post_restrictions_init_2
    
entry_point_boucle_verif_post_restrictions_init_2:
    mov r13, 0
boucle_verif_post_restrictions_init_2:
    movzx edi, word[pre_circles_x+r13*WORD]
    movzx esi, word[pre_circles_y+r13*WORD]
    movzx edx, word[post_circles_x+r14*WORD]
    movzx ecx, word[post_circles_y+r14*WORD]
    
    call points_gap
    
    movzx r10, word[pre_circles_r+r13*WORD]
    movzx r11, word[post_circles_r+r14*WORD]
    add r10, r11
    
    cmp rax, r10
    jl boucle_cercles_tangents
    
next_post_init_2:
    inc r13
    cmp r13, NB_PRE_CIRCLES
    jb boucle_verif_post_restrictions_init_2
    
    mov r13, 0
boucle_verif_post_restrictions_tan_2:
    cmp r13, r14
    je next_post_tan_2
    
    movzx edi, word[post_circles_x+r13*WORD]
    movzx esi, word[post_circles_y+r13*WORD]
    movzx edx, word[post_circles_x+r14*WORD]
    movzx ecx, word[post_circles_y+r14*WORD]
    
    call points_gap
    
    movzx r10, word[post_circles_r+r13*WORD]
    movzx r11, word[post_circles_r+r14*WORD]
    add r10, r11
    
    cmp rax, r10
    jl boucle_cercles_tangents
        next_post_tan_2:
            inc r13
            
            cmp r13, r14
            jb boucle_verif_post_restrictions_tan_2
            
        generate_circle_step_two:
            mov    rdi, qword[display_name]
            mov    rsi, qword[window]
            mov    rdx, qword[gc]
            mov    cx, word[post_circles_r_tampon+r14*WORD]

            mov    bx, word[post_circles_x+r14*WORD]
            sub    bx, cx
            movzx  rcx, bx

            mov    bx, word[post_circles_y+r14*WORD]
            mov    r15w, word[post_circles_r_tampon+r14*WORD]
            sub    bx, r15w
            movzx  r8, bx
            movzx  r9, word[post_circles_r_tampon+r14*WORD]
            shl    r9, 1
            mov    rax, 23040
            push   rax
            push   0
            push   r9

            call   XDrawArc
            add    rsp, 24
            
        post_inner_arc:
            mov    r15w, word[post_circles_r_tampon+r14*WORD]
            cmp    r15w, 0
            je     boucle_affichage_post
                
            mov    ax, word[color_counter]
            mov    bx, NB_KIT_STEP
            xor    dx, dx
            div    bx
                
            movzx  r15, dx
                
            mov    rdi, qword[display_name]
            mov    rsi, qword[gc]
            mov    edx, dword[kit_colors+r15*DWORD]
            call   XSetForeground
                
            dec    word[post_circles_r_tampon+r14*WORD]
            inc    word[color_counter]
            jmp    generate_circle_step_two

    ; FIN ETAPE 2

    boucle_affichage_post:
        ; affichage dans la sortie standard (non demandé)
        mov    rdi, fmt_tan_circles
        movzx  rsi, r14b
        movzx  rdx, word[post_circles_x+r14*WORD]
        movzx  rcx, word[post_circles_y+r14*WORD]
        movzx  r8, word[post_circles_r+r14*WORD]
        mov    rax, 0
        call   printf

        inc    word[i]
        cmp    word[i], NB_POST_CIRCLES
        jb     boucle_cercles_tangents
        
    fin_affichage_cercles:
        mov byte[bool_fin], 1

    flush:
        mov    rdi, qword[display_name]
        call   XFlush
        jmp    boucle ; stand-by: ça cause divers problèmes
        mov    rax, 34
        syscall

    closeDisplay:
        mov    rax, qword[display_name]
        mov    rdi, rax
        call   XCloseDisplay
        xor    rdi, rdi
        call   exit
        
    ; Fonction pour générer un nombre aléatoire
    ; random_number(rdi(nombre maximum))
    ; => rax(nombre aléatoire)
    random_number:
    relancer:
        rdrand  ax
        jc      valide
        jmp     relancer
    valide:
        mov     dx, 0
        div     di
        mov     ax, dx
        ret

    ; points_gap(edi(x1), esi(y1), edx(x2), ecx(y2))
    ; => rax(distance)
    points_gap:
        ; Calculer (x1 - x2)^2
        mov     eax, edi
        sub     eax, edx
        imul    eax, eax

        ; Calculer (y1 - y2)^2
        mov     ebx, esi
        sub     ebx, ecx
        imul    ebx, ebx

        ; Calculer (x1 - x2)^2 + (y1 - y2)^2
        add     eax, ebx

        ; Convertir le résultat en flottant
        cvtsi2sd xmm0, eax

        ; Calculer la racine carrée
        sqrtsd  xmm1, xmm0

        ; Convertir la racine carrée en entier et arrondir
        cvtsd2si eax, xmm1

        ret
