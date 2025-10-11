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
![Ondas](Figuras/wave1.png)

---

## 🧱 Síntesis e implementación (Vivado 2024.1)
- Estrategias por defecto (Synthesis/Implementation Defaults).
- **Cumple temporización a 125 MHz** (WNS/TNS ≥ 0).
- Utilización baja de LUT/FF, sin BRAM/DSP.

Reporte de implementación:
![Implementación](Figuras/report_implementation.png)

Utilización (referencia):
![Utilización](Figuras/report_utilization.png)

---

## ⚡ Potencia (estimación)
Potencia total ~ **0.095 W**, dominada por componente estático.  
![Power](Figuras/power_report.png)

---

## ⏱️ Análisis temporal
Resumen de slacks y checks de temporización post-implementación:  
![Timing summary](Figuras/timing.png)  
Detalle de setup/hold/pulse width:  
![Timing detail](Figuras/TIMING_IMPLEMENTATION.png)

Criterios de validez:
- **WNS/TNS ≥ 0 ns** (setup).
- **WHS/THS ≥ 0 ns** (hold).
- **Pulse Width ≥ 0 ns**.
- **Endpoints fallidos = 0**.

---

## 🔌 Pruebas en hardware
Conexión FTDI 3.3 V, GND común y cruces RX/TX.  
![Hardware](Figuras/hardware.jpeg)

Terminal serie (AccessPort) a **115200 8N1**:  
![AccessPort](Figuras/accessport.png)

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

## ✅ Buenas prácticas
- Crear **tests** antes de implementar para evitar tiempo perdido en producción.
- Revisar el **.xdc** para prevenir fallos de conexión o daño de pines.
- Asegurar **3.3 V LVCMOS** en ambos extremos (FPGA y USB–UART).
- Verificar **RX/TX cruzados** correctamente.
- Probar **módulos por separado** (`uart_rx`, `uart_tx`, contador) antes de integrar.

---

## 📜 Licencia
Este proyecto se distribuye bajo la licencia **MIT**. Ver `LICENSE` para más detalles.

## 🙌 Agradecimientos
- Manual de referencia de Arty Z7 de Digilent.  
- Guías UG901/UG903/UG904/UG949 de AMD Xilinx.  
- Documentación general de UART.


