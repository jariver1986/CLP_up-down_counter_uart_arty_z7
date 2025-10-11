# Contador ascendente/descendente controlado por UART (Arty Z7-10)

Sistema en VHDL que integra `uart_rx`, `uart_tx` y un contador up/down de 4 bits, con eco en consola serie. Diseñado para la placa **Arty Z7-10 (xc7z010clg400-1)** usando **Vivado 2024.1** y **XSIM**.

## 🎯 Objetivos
- Implementar receptor y transmisor UART 8N1 a **115200 bps**.
- Integrar un **contador de 4 bits** con control por comandos (`+`, `-`, `s`, `p`, `z`).
- Verificar por **simulación** y **hardware**, con eco del valor en la terminal.

---

## 🧩 Arquitectura
<img width="1885" height="891" alt="esquematico_general" src="https://github.com/user-attachments/assets/8b4e66ce-c6cc-4a13-98e0-a6a36a0be11a" />


Módulos principales:
- `uart_rx`: recepción 8N1 con sobremuestreo y `data_valid`.
- `uart_tx`: transmisión 8N1 con arbitraje mediante `tx_busy`.
- `updown_counter`: contador de 4 bits con `clear`, `step_up`, `step_dn`, `enable`.

---

## 🛠️ Hardware y conexiones
- **FPGA**: Arty Z7-10 (Zynq-7000, `xc7z010clg400-1`).
- **Serial**: Adaptador **USB–UART** (FTDI) a **3.3 V LVCMOS**.
- **Cruce de señales**: TX módulo ↔ RX FPGA, TX FPGA ↔ RX módulo.
- **Terminal**: 115200 bps, 8N1, sin control de flujo.

### Pinout (XDC)
| Señal      | Pin | IOSTANDARD | Nota                          |
|------------|-----|------------|-------------------------------|
| `clk`      | H16 | LVCMOS33   | 125 MHz (periodo 8 ns).       |
| `rst_n`    | M20 | LVCMOS33   | Activo en bajo, con pull-up.  |
| `uart_rx`  | Y18 | LVCMOS33   | Entrada desde USB–UART (TX).  |
| `uart_tx`  | Y16 | LVCMOS33   | Salida hacia USB–UART (RX).   |
| `leds[0]`  | R14 | LVCMOS33   | LED0.                         |
| `leds[1]`  | P14 | LVCMOS33   | LED1.                         |
| `leds[2]`  | N16 | LVCMOS33   | LED2.                         |
| `leds[3]`  | M14 | LVCMOS33   | LED3.                         |

---


---

## ▶️ Simulación (XSIM)
1. Abrir el proyecto o compilar fuentes manualmente.
2. Ejecutar el **testbench** `tb_top_uart_counter.vhd`.
3. Secuencia incluida en el TB:
   - `z` → clear a 0.
   - `+` `+` → contador = 2 (0010).
   - `s` → modo automático.
   - `p` → pausa.

Salida esperada en ondas:
<img width="1103" height="665" alt="wave1" src="https://github.com/user-attachments/assets/88f1734e-8b59-415d-8aa6-a27e47e16be4" />


---

## 🧱 Síntesis e implementación (Vivado 2024.1)
- Estrategias por defecto (Synthesis/Implementation Defaults).
- **Cumple temporización a 125 MHz** (WNS/TNS ≥ 0).
- Utilización baja de LUT/FF, sin BRAM/DSP.

Reporte de implementación:
<img width="717" height="139" alt="report_implementation" src="https://github.com/user-attachments/assets/089476e6-5974-4037-a3a1-0773ef18bdb5" />

---

## ⚡ Potencia (estimación)
Potencia total ~ **0.095 W**, dominada por componente estático.  
<img width="680" height="413" alt="power_report" src="https://github.com/user-attachments/assets/b6629263-4535-476a-9115-3f9e68745130" />


---

## ⏱️ Análisis temporal
Resumen de slacks y checks de temporización post-implementación:  
<img width="881" height="176" alt="timing" src="https://github.com/user-attachments/assets/47f3fc9c-6c73-49a8-86ab-2ccddb0e4eac" />


Criterios de validez:
- **WNS/TNS ≥ 0 ns** (setup).
- **WHS/THS ≥ 0 ns** (hold).
- **Pulse Width ≥ 0 ns**.
- **Endpoints fallidos = 0**.

---

## 🔌 Pruebas en hardware
Conexión FTDI 3.3 V, GND común y cruces RX/TX.  
![hardware](https://github.com/user-attachments/assets/b8ad566a-cbe3-45e8-b8a4-ec464bee8f08)


Terminal serie (AccessPort) a **115200 8N1**:  
<img width="564" height="395" alt="accessport" src="https://github.com/user-attachments/assets/4d3ab301-c4ed-43f2-8657-9c50ab97c0f0" />


---

## 🗺️ Comandos UART
| Comando | Acción                                 |
|--------:|----------------------------------------|
| `z`     | Reinicia contador a 0.                 |
| `+`     | Incrementa una unidad.                 |
| `-`     | Decrementa una unidad.                 |
| `s`     | Activa modo automático (tick 10 Hz).   |
| `p`     | Pausa modo automático.                 |

El valor del contador se **eco** en ASCII **hex** (`0..F`).

---


