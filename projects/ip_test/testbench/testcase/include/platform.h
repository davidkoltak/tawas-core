
#ifndef PLATFORM_H
#define PLATFORM_H

#define DEVICE_NAME "test platform - no device in particular"

#define TEST_REG_BASE       0xFFFFFFF0
#define RCN_RAM0_BASE       0xFFFE0000
#define RCN_UART0_BASE      0xFFFFFFB8

#define RCN_RAM1_BASE       0xFF0E0000
#define RCN_DMA1_BASE       0xFF0FFFC0

#define RCN_RAM2_BASE       0xFF1E0000
#define RCN_UART1_BASE      0xFF1FFFB8
#define RCN_DMA2_BASE       0xFF1FFFC0

#define RCN_UART0_DMA       RCN_DMA1_BASE
#define RCN_UART0_TX_REQ    1
#define RCN_UART0_RX_REQ    2

#define RCN_UART1_DMA       RCN_DMA1_BASE
#define RCN_UART1_TX_REQ    3
#define RCN_UART1_RX_REQ    4
     
#endif
