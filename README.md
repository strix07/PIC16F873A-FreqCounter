# Frecuencímetro digital con PIC16F873A

## Descripción

Este proyecto consistió en el desarrollo de un frecuencímetro digital basado en el microcontrolador PIC16F873A.

El sistema es capaz de medir señales de entrada entre 0 y 40 KHz, mostrando el resultado en un banco de 8 LEDs que indican el rango en el que se encuentra la frecuencia medida.

Adicionalmente, se implementó la selección de 3 rangos de medición mediante un conmutador rotativo:

Rango 1: 0 a 10 KHz
Rango 2: 0 a 20 KHz
Rango 3: 0 a 40 KHz
El rango seleccionado se indica en un display de 7 segmentos.

<br>

<div align="center">
  <img src="https://github.com/strix07/PIC16F873A-FreqCounter/assets/142692042/f3d7bd69-51ea-4c1b-815e-ce920b3de63e">
</div>
<br>


## Diagrama del circuito

<br>

<div align="center">
  <img src="https://github.com/strix07/PIC16F873A-FreqCounter/assets/142692042/e8da716a-85c0-4ec2-a453-6f4b9755a0d5">
</div>

<br>

Como puede verse, la señal a medir ingresa por un zener para adaptar sus niveles lógicos a TTL. Luego es conectada a un pin de entrada del PIC.

Mediante programación del Timer 1 y el Timer 0 como contadores, se mide la cantidad de pulsos en un intervalo de 1 segudo para calcular la frecuencia.

## Descripción del hardware
A nivel de hardware se utilizaron los siguientes componentes:

- Microcontrolador PIC16F873A en encapsulado DIP40
- Cristal de 4MHz
- Display de ánodo común de 7 segmentos
- 8 LEDs indicadores
- Selector rotativo de 3 posiciones
- Circuito acondicionador de señal con diodo Zener y resistencias
- Pulsador de reset

## Descripción del software
- El programa fue desarrollado en ensamblador utilizando las siguientes características
- Configuración de los puertos de E/S
- Inicialización de variables y registros
- Configuración del Timer 0 como contador
- Configuración del Timer 1 en modo temporizador para intervalo de 1 seg
- Rutina de atención a la interrupción del Timer 1
- Lectura y decodificación de contador para mostrar resultado

## A continuación, se adjunta un video del funcionamiento del circuito.

https://drive.google.com/file/d/1J1bFbc2gkoG14FvXNKewcP1-8h0xOuFM/view?usp=drivesdk

## Resultados
Tanto en simulación como en la implementación física se comprobó el correcto funcionamiento del frecuencímetro, cumpliendo con las especificaciones establecidas.

Se evidenció el uso de periféricos avanzados del PIC16F873A así como el manejo de interrupciones para el desarrollo de la aplicación.

El código completo se encuentra comentado y documentado en este repositorio.
