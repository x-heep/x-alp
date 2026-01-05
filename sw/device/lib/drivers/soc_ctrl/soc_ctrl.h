#ifndef _SOC_CTRL_H_
#define _SOC_CTRL_H_

typedef struct soc_ctrl {
    uint32_t base_addr;
} soc_ctrl_t;

void soc_ctrl_set_exit_value(soc_ctrl_t *ctrl, uint32_t value){
    // Dummy implementation
}
void soc_ctrl_set_valid(soc_ctrl_t *ctrl, uint8_t valid){
    // Dummy implementation
}
uint32_t soc_ctrl_get_frequency(soc_ctrl_t *ctrl){
    // Dummy implementation
    return 16000000; // Example: 16 MHz
}
#endif  // _SOC_CTRL_H_