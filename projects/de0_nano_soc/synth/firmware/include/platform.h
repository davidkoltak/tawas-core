
#ifndef PLATFORM_H
#define PLATFORM_H

#define DEVICE_NAME "Terasic DE0 Nano SoC"

#define TEST_REG_BASE       0xFFFFFFF0

#define RCN_RAM_BASE       0xFFFE0000

#define RCN_UART_BASE       0xFFFFFFB8

#define RCN_DMA_BASE        0xFF1FFFC0

#define RCN_UART_DMA        RCN_DMA_BASE
#define RCN_UART_TX_REQ     14
#define RCN_UART_RX_REQ     15

#endif
