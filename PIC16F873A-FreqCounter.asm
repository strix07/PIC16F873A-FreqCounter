;===========================================================
;PROYECTO FRECUENCIOMETRO
list p=16f873a 
include <p16f873a.inc> 
__CONFIG _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF

;Este programa consiste en un frecuenciometro de 3 escalas 10k,20k y 40k, dependidiendo de cual
;sea la escala selecccionada se mostrara el resultado en una tira de leds ubicados en el PUERTO C
;para ello necesitaremos medir la cantidad de pulsos que ocurren en 1s, esto lo haremos iutilizando
;el TIMER0 como contador, que como veremos mas adelante solo podrá leer 250 pulos asi que necesitaremos
;otro registro auxiliar que se incremente cada vez que se cuenten 250 pulsos, una vez configurado
;el TIMER0 como contador necesitaremos, algo que nos avise cuando halla pasado 1s, para esto utilizaremos
;el TIMER1, el cual solo podemos configurarlo como maximo para 500ms como se muestra abajo:

;   TMR1 => 0 A 65535
;
;   TMR1 = 65535 - ((TIEMPO_DESEADO*FOSC)/(PRESCALER*4)) - 1  
;   (500mS) TMR1 = 65535 - ((500ms*4MHZ)/(8*4)) -1
;   (500mS) TMR1 = 65535 - 62500 -1 = 3034
;   TMR1 = 3034 => 0x0BDCA

;de forma que debemos ejecutar el TIMER1 2 veces para  que justo pasado 1s se ejecute una interrupcion,
;la cual hara que el TIMER0 deje de contar y nos muestre cuantos pulsos se ejecutaron en 1s


;==============================================================
;VARIABLES 

	CUENTA equ 21h				;indica cuantas veces se ejecutado el TIMER1
	ESCALA equ 22h				;indica la escala que se esta usando
	CONT equ 23h				;registro auxiliar, se incrementa cada vez que 
								;ESCALAx250=FRECUENCIA EN LA QUE ENCIENDE 1 LED
	CONT2 equ 24h				;Indica la frecuencia y cuantos leds se deben encender
								;EJEMPLO para la escala 1: 5X250=1250 (cada vez que se incremete este contador
								;se encendera un led que equivale a 1250 Hz, este contador se incrementara
								;como maximo 8 veces ya que son 8 leds, en entones freqmax=8x1250=10kHZ
	CONT3 equ 25h				;indica que ya ejecutaron 2 ciclos del timer1 por lo cual ya paso 1s
	LED equ 26h					;indica la Frecuencia de la señal de entrada
	

;==============================================================
;REDIRECCIONAMIENTO: redireciona el programa dependiendo si se 
;activó un reset o una interrupcion externa

RESET	
	ORG	0
	GOTO	INICIO
	ORG	4
	GOTO	INT_TMR1

;=========================================================================
;RUTINA DE INICIO: configura los puertos y registroa que se van a utilizar

INICIO

	BCF STATUS,RP1			;
	BSF STATUS,RP0			;coloco en 1 el bit RP0 (seleccion banco 1)
 
   	CLRF PORTB				;todo salidas expeto RB0
	
	MOVLW b'00111000'		;
	MOVWF OPTION_REG		;configuro el timer0
	
	CLRF PORTC				;todo salidas expeto RB0

	BSF	PIE1,0 				;TMR1 ENABLE

    movlw 06h				;configuro el puerto A como entrada digital
	movwf ADCON1			;
	MOVLW b'00010111'		;
	MOVWF PORTA				;configuro el puerto A

	BCF STATUS,RP0			;coloco en 0 el bit RP0 (seleccion banco 0)	

	MOVLW 0FFH				;
	MOVWF PORTB				;apago el display
	MOVLW 0FFH				;
	MOVWF PORTC				;apago la tira de led
	MOVLW 0FEH				;
	MOVWF LED				;si la frecuencia es muy baja encender solo un led

	BCF	T1CON,1 ;TEMPORIZADOR
	BSF	T1CON,5
	BSF	T1CON,4 ;PRESCALER 8	
	BSF	INTCON,7; GIE
	BSF	INTCON,6; PIEI
	BCF	PIR1,0; FLANCO TIMER1

;==================================================================
;RUTINA DE BUCLE: solo se sale si si se seleciona una escala, una vez selecionada la escala
;se guarda, se configura el registro ESCALA y se muestra en el display que rango se se
;seleccinó 10k=RANGO1,20k=RANGO2,40k=RANGO3

BUCLE
	BTFSS PORTA,0 		;si el pin A0=0 
	GOTO FREQ10K		;ir a FREQ10K
	BTFSS PORTA,1 		;si el pin A1=0 
	GOTO FREQ20K		;ir a FREQ20K
	BTFSS PORTA,2		;si el pin A2=0 
	GOTO FREQ30K		;ir a FREQ40K
	GOTO BUCLE			;sino repite

FREQ10K
	MOVLW .5			;			
	MOVWF ESCALA		;guardo la ecala
	movlw B'11111001'	;muestro rango 1 en el display
	movwf PORTB			;
	GOTO START			;comenzar conteo

FREQ20K
	MOVLW .10			;
	MOVWF ESCALA		;guardo la ecala
	movlw B'10100100'	;muestro rango 1 en el display
	movwf PORTB			;
	GOTO START			;comenzar conteo

FREQ30K
	MOVLW .20			;
	MOVWF ESCALA		;guardo la ecala
	movlw B'10110000'	;muestro rango 1 en el display
	movwf PORTB			;
	GOTO START			;comenzar conteo

;=======================================================================================
;RUTINA DE START: enciende el TIMER1 y lo configura para  que se ejecute una interrupcion
;en luego de 500ms como se calculo anteriormente

START
	CLRF CONT3				;borro el contador 3				
	BSF	T1CON,0				;TMR1 ON
	MOVLW 0Bh				;timer1 para 500ms
	MOVWF TMR1H				;
	MOVLW 0DAh				;
	MOVWF TMR1L				;
	CLRF TMR0				;reseteo timer 0

;=======================================================================================
;RUTINA DE TIMER: en caso de pasado 2 segundos regresa a bucle para ver si se cambio la escala
;sino reviso si TIMER0 contó 250 pulsos, siya lo hizo va hacia CONTADOR.

TIMER		
	MOVF CONT3,W			
	SUBLW 55H
	BTFSC STATUS,Z			;si ya paso 1s 
	GOTO BUCLE				;ver que escala esta pulsada
	MOVF TMR0,W				;veo cuantos pulsos se han ocurrido
	SUBLW .250				;comparo con 250
	BTFSC STATUS,Z
	GOTO CONTADOR			;si es igual a 250 ir a CONTADOR
	GOTO TIMER				;sino esperar a que TIMER0=250

;=======================================================================================
;RUTINAS DE CONTADOR: avisa que ya se contaron 250 pulsos, y revisa si ya se ejecuto la cantidad 
;de veces para que encienda un led (ESCALAx250=FRECUENCIA EN LA QUE ENCIENDE 1 LED)
;si es asi va hacia FRECUENCIOMETRO

CONTADOR
	INCF CONT,1					;indico que ya se contaron 250 pulsos
	MOVF CONT,W					;
	SUBWF ESCALA,W				;				
	BTFSC STATUS,Z				;veo si debo encender un led mas
	GOTO FRECUENCIOMETRO		;si es asi encender otro led
	CLRF TMR0					;sino reseteo timer 0
	GOTO TIMER					;cuento oros 250 pulsos

;=======================================================================================
;RUTINAS DE FRECUENCIMETRO: se ejecuta cuando la frecuencia a subrepasado ESCALAx250
;indicado que se debe aumentar en 1 el numero de leds encendidos y guardarlos en la
;direccion LED para que si se ejecuta la interrupcion se muestre en el PUERTO C

FRECUENCIOMETRO	
	CLRF CONT					;indico que se encendio el led 			
	INCF CONT2,1				;aumento en 1 la cantidad de leds que deben verse 

	MOVF CONT2,W				;	
	SUBLW .1					;la cantidad leds que deben verse es 1?
	BTFSC STATUS,Z				;	
	GOTO LED1					;si es asi ir a LED1
	
	MOVF CONT2,W				;
	SUBLW .2					;la cantidad leds que deben verse es 2?
	BTFSC STATUS,Z				;
	GOTO LED2					;si es asi ir a LED2

	MOVF CONT2,W				;repito hasta llegar a 8
	SUBLW .3
	BTFSC STATUS,Z
	GOTO LED3

	MOVF CONT2,W
	SUBLW .4
	BTFSC STATUS,Z
	GOTO LED4

	MOVF CONT2,W
	SUBLW .5
	BTFSC STATUS,Z
	GOTO LED5

	MOVF CONT2,W
	SUBLW .6
	BTFSC STATUS,Z
	GOTO LED6

	MOVF CONT2,W
	SUBLW .7
	BTFSC STATUS,Z
	GOTO LED7

	MOVF CONT2,W
	SUBLW .8
	BTFSC STATUS,Z
	GOTO LED8

	GOTO TIMER					;si no es ninguno volver a timer

LED1	
	MOVLW B'11111110'			;guardar que solo se debe mostrar 1 led
	MOVWF LED					;
	CLRF TMR0					;resetear TIMER0
	GOTO TIMER					;volver a hacer el proceso

LED2	
	MOVLW B'11111100'			;repetir...
	MOVWF LED
	CLRF TMR0
	GOTO TIMER

LED3	
	MOVLW B'11111000'
	MOVWF LED
	CLRF TMR0
	GOTO TIMER

LED4	
	MOVLW B'11110000'
	MOVWF LED
	CLRF TMR0
	GOTO TIMER

LED5	
	MOVLW B'11100000'
	MOVWF LED
	CLRF TMR0
	GOTO TIMER

LED6	
	MOVLW B'11000000'
	MOVWF LED
	CLRF TMR0
	GOTO TIMER

LED7	
	MOVLW B'10000000'
	MOVWF LED
	CLRF TMR0
	GOTO TIMER

LED8	
	MOVLW B'00000000'
	MOVWF LED
	DECF CONT2				;indico que llegue al maximo de esta escala
	CLRF TMR0				;resetar TIMER0
	GOTO TIMER				;volver a hacer el proceso

;=======================================================================================
;RUTINAS INTt_TMR1: se ejecuta pasado 500ms y se encarga deindicar que se ejecuto 1 vez 
;la interrupcion del TIMER!, volver a configurar el TIMER1 para otros 500ms y regresar
;a seguir contado los pulos hasta que pasen otros 500ms, si ya se ejecuto 2 eveces
;el TIMER1 va hacia VOLVER

INT_TMR1

	INCF CUENTA,1			;indico que se ejecuto TIMER! una vez
	MOVF CUENTA,W			;
	SUBLW 2					;
	BTFSC STATUS,Z			;ya se ejecutó 2 veces ?
	GOTO  VOLVER			;ir a volver

	MOVLW	0X0B			;sino
	MOVWF	TMR1H			;configurar el TIMER1 para otros 500ms
	MOVLW	0XDA			;
	MOVWF	TMR1L			;
	BCF	PIR1,0				;indico que ua se ejecuto la interrrupcion
	RETFIE					;sigo contando los pulsos con el TIMER0

;=======================================================================================
;RUTINAS VOLVER: se ejecuta pasado 1s, se encarga de avisar que ya pasó 1s, mostrar en
;la tira de leds la frecuencia de la señal de entrada, y resetear los registros que se
;utilizan para contar los pulsos y de esta forma poder volver a leer la frecuencia una vez 
;pasado otro segundo.

VOLVER
	MOVLW 55H				;
	MOVWF CONT3				;indico que ya paso 1s
	CLRF CUENTA				;		
	MOVF LED,W				;
	MOVWF PORTC				;muestro la frecuencia en la tira de leds
	CLRF CONT				;reinicio los registros para el conteo
	CLRF CONT2				;
	MOVLW 0FEH				;
	MOVWF LED				;si la frecuencia es muy baja encender solo un led
	CLRF TMR0				;reseteo TIMER0
	BCF	PIR1,0				;indico que ua se ejecuto la interrrupcion
	RETFIE					;realizo el conteo para el proximo segundo

	END
	