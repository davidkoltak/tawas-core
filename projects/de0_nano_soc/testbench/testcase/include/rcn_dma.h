
#ifndef RCN_DMA_H
#define RCN_DMA_H

#define RCN_DMA_SRC_REQ(x)  (x << 0)
#define RCN_DMA_DST_REQ(x)  (x << 4)
#define RCN_DMA_SRC_INC     (1 << 8)
#define RCN_DMA_DST_INC     (1 << 9)
#define RCN_DMA_TRANS_BYTE  (0 << 10)
#define RCN_DMA_TRANS_HALF  (1 << 10)
#define RCN_DMA_TRANS_WORD  (2 << 10)
#define RCN_DMA_NULL_TERM   (1 << 12)

#endif
