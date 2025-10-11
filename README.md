# Contador ascendente/descendente controlado por UART (Arty Z7-10)

Sistema en VHDL que integra `uart_rx`, `uart_tx` y un contador up/down de 4 bits, con eco en consola serie. Diseñado para la placa **Arty Z7-10 (xc7z010clg400-1)** usando **Vivado 2024.1** y **XSIM**.

## 🎯 Objetivos
- Implementar receptor y transmisor UART 8N1 a **115200 bps**.
- Integrar un **contador de 4 bits** con control por comandos (`+`, `-`, `s`, `p`, `z`).
- Verificar por **simulación** y **hardware**, con eco del valor en la terminal.

---

## 🧩 Arquitectura
![Esquemático general](Figuras/esquematico_general.png)

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

## 📂 Estructura del repositorio
