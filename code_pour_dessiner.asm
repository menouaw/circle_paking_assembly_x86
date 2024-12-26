; external functions from X11 library
extern XOpenDisplay
extern XDisplayName
extern XCloseDisplay
extern XCreateSimpleWindow
extern XMapWindow
extern XRootWindow
extern XSelectInput
extern XFlush
extern XCreateGC
extern XSetForeground
extern XDrawLine
extern XNextEvent
extern XDrawArc

; external functions from stdio library (ld-linux-x86-64.so.2)    
extern printf
extern exit

%define	StructureNotifyMask	131072
%define KeyPressMask		1
%define ButtonPressMask		4
%define MapNotify		19
%define KeyPress		2
%define ButtonPress		4
%define Expose			12
%define ConfigureNotify		22
%define CreateNotify 16
%define QWORD	8
%define DWORD	4
%define WORD	2
%define BYTE	1

%define WIDTH	600
%define HEIGHT	600
%define RAYON_MAX 300

%define NB_PRE_CIRCLES 3

global main 

section .bss
display_name:	resq	1
screen:			resd	1
depth:         	resd	1
connection:    	resd	1
width:         	resd	1
height:        	resd	1
window:		resq	1
gc:		resq	1
i: resb 1

section .data

event:		times	24 dq 0
pre_circles_x: times NB_PRE_CIRCLES dw 0
pre_circles_y: times NB_PRE_CIRCLES dw 0
pre_circles_r: times NB_PRE_CIRCLES dw 0
format: db "Cercle %d : x = %d, y = %d, r = %d", 10, 0 ; Format d'affichage
crlf: db 10,0 ; saut de ligne

section .text
	
;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:
;###########################################################
; Mettez ici votre code qui devra s'exécuter avant le dessin
;###########################################################
mov byte[i], 0




;###############################
; Code de création de la fenêtre
;###############################
xor     rdi,rdi
call    XOpenDisplay	; Création de display
mov     qword[display_name],rax	; rax=nom du display

; display_name structure
; screen = DefaultScreen(display_name);
mov     rax,qword[display_name]
mov     eax,dword[rax+0xe0]
mov     dword[screen],eax

mov rdi,qword[display_name]
mov esi,dword[screen]
call XRootWindow
mov rbx,rax

mov rdi,qword[display_name]
mov rsi,rbx
mov rdx,10
mov rcx,10
mov r8,WIDTH	; largeur
mov r9,HEIGHT	; hauteur
push 0xFFFFFF	; background  0xRRGGBB
push 0x00FF00
push 1
call XCreateSimpleWindow
mov qword[window],rax

mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,131077 ;131072
call XSelectInput

mov rdi,qword[display_name]
mov rsi,qword[window]
call XMapWindow

mov rsi,qword[window]
mov rdx,0
mov rcx,0
call XCreateGC
mov qword[gc],rax

mov rdi,qword[display_name]
mov rsi,qword[gc]
mov rdx,0x000000	; Couleur du crayon
call XSetForeground

boucle: ; boucle de gestion des évènements
mov rdi,qword[display_name]
mov rsi,event
call XNextEvent

cmp dword[event],ConfigureNotify	; à l'apparition de la fenêtre
je dessin							; on saute au label 'dessin'

cmp dword[event],KeyPress			; Si on appuie sur une touche
je closeDisplay						; on saute au label 'closeDisplay' qui ferme la fenêtre
jmp boucle

;#########################################
;#		DEBUT DE LA ZONE DE DESSIN		 #
;#########################################
dessin:

;couleur du cercle
mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,0xFF0000	; Couleur du crayon ; rouge
call XSetForeground

; Dessin du cercle
boucle_cercles:
mov r14b, byte[i]
mov rdi, WIDTH
call random_number
mov r10w, ax

mov rdi, HEIGHT
call random_number
mov r11w, ax

mov rdi, RAYON_MAX
call random_number
mov r12w, ax

mov rdi,qword[display_name]
mov rsi,qword[window]		
mov rdx,qword[gc]

mov cx,r12w	; RAYON DU CERCLE
mov word[pre_circles_r+r14*WORD], r12w

mov bx,r10w	; COORDONNEE en X DU CERCLE
mov word[pre_circles_x+r14*WORD], bx

sub bx,cx				
movzx rcx,bx			

mov bx,r11w	; COORDONNEE en Y DU CERCLE
mov word[pre_circles_y+r14*WORD], bx
mov r15w,r12w	; RAYON DU CERCLE
sub bx,r15w
movzx r8,bx		
movzx r9,r12w	; RAYON DU CERCLE
shl r9,1
mov rax,23040
push rax
push 0
push r9

boucle_verif_chevauchement:

boucle_verif_adjacence:

call XDrawArc

boucle_affichage:
    ; Chargement de l'adresse de la chaîne de format dans rdi
    mov rdi, format

    ; Copie de l'indice i dans rsi (premier argument entier de printf)
    movzx rsi, r14b                     ; r14b <=> byte[i]

    movzx rdx, word[pre_circles_x+r14*WORD] ; on copie la valeur à l'adresse pre_circles_x dans rdx

    movzx rcx, word[pre_circles_y+r14*WORD] ; on copie la valeur à l'adresse pre_circles_y dans rcx
    
    movzx r8, word[pre_circles_r+r14*WORD]

    mov rax, 0 
    call printf  
	
	
; Incrémentation et comparaison du compteur
inc   byte[i]        ; Incrémentation du compteur
cmp   byte[i], NB_PRE_CIRCLES-1    ; Comparaison du compteur à 3
jb    boucle_cercles   ; Saut si bl < 3 (retour au début de la boucle)

; ############################
; # FIN DE LA ZONE DE DESSIN #
; ############################
;jmp flush

flush:
mov rdi,qword[display_name]
call XFlush
jmp boucle
mov rax,34
syscall

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit
	
; Fonction pour générer un nombre aléatoire
; random_number(rdi(nombre maximum))
; => rax(nombre aléatoire)
random_number:
 relancer:
     rdrand ax
     jc valide
     jmp relancer
 valide:
     xor dx, dx
     div di
     mov ax, dx
 ret

; points_gap(edi(x1), esi(y1), edx(x2), r8d(y2))
; => rax(distance)
points_gap: 
    ; Calculer (x1 - x2)^2
    mov eax, edi
    sub eax, edx
    imul eax, eax 

    ; Calculer (y1 - y2)^2
    mov ebx, esi
    sub ebx, r8d
    imul ebx, ebx

    ; Calculer (x1 - x2)^2 + (y1 - y2)^2
    add eax, ebx

    ; Convertir le résultat en flottant
    cvtsi2sd xmm0, eax 

    ; Calculer la racine carrée
    sqrtsd xmm1, xmm0 

    ; Convertir la racine carrée en entier et arrondir
    cvtsd2si eax, xmm1 

    ret
