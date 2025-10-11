## Clock PL 125 MHz
set_property PACKAGE_PIN H16 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 8.000 -name sys_clk [get_ports clk]

## Reset activo en 0 (SW0)
set_property PACKAGE_PIN M20 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
set_property PULLUP true [get_ports rst_n]

## UART RX desde PMOD JA1 (TX del USB-UART → JA1)
set_property PACKAGE_PIN Y18 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]
set_property PULLUP true [get_ports uart_rx]

## LEDs
set_property PACKAGE_PIN R14 [get_ports {leds[0]}]
set_property PACKAGE_PIN P14 [get_ports {leds[1]}]
set_property PACKAGE_PIN N16 [get_ports {leds[2]}]
set_property PACKAGE_PIN M14 [get_ports {leds[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[*]}]

## UART TX hacia PMOD JA2 (conectar a RX del USB-UART)
set_property PACKAGE_PIN Y16 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]


