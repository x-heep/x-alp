/*
                              *******************
******************************* H SOURCE FILE *******************************
**                            *******************                          **
**                                                                         **
** project  : x-heep                                                       **
** filename : dma_structs.h                                 **
** date     : 15/12/2025                                                      **
**                                                                         **
*****************************************************************************
**                                                                         **
**                                                                         **
*****************************************************************************

*/

/**
* @file   dma_structs.h
* @date   15/12/2025
* @brief  Contains structs for every register
*
* This file contains the structs of the registes of the peripheral.
* Each structure has the various bit fields that can be accessed
* independently.
* 
*/

#ifndef _DMA_STRUCTS_H
#define DMA_STRUCTS

/****************************************************************************/
/**                                                                        **/
/**                            MODULES USED                                **/
/**                                                                        **/
/****************************************************************************/

#include <inttypes.h>
#include "core_v_mini_mcu.h"

/****************************************************************************/
/**                                                                        **/
/**                       DEFINITIONS AND MACROS                           **/
/**                                                                        **/
/****************************************************************************/

#define dma_peri(channel) ((volatile dma *) (DMA_START_ADDRESS + DMA_CH_SIZE * channel))

/****************************************************************************/
/**                                                                        **/
/**                       TYPEDEFS AND STRUCTURES                          **/
/**                                                                        **/
/****************************************************************************/



typedef struct {

  uint32_t SRC_PTR;                               /*!< Input data pointer (word aligned)*/

  uint32_t DST_PTR;                               /*!< Output data pointer (word aligned)*/

  uint32_t ADDR_PTR;                              /*!< Addess data pointer (word aligned)*/

  uint32_t SIZE_D1;                               /*!< Number of elements to copy from, defined with respect to the first dimension - Once a value is written, the copy starts*/

  uint32_t SIZE_D2;                               /*!< Number of elements to copy from, defined with respect to the second dimension*/

  uint32_t STATUS;                                /*!< Status bits are set to one if a given event occurred*/

  uint32_t SRC_PTR_INC_D1;                        /*!< Increment the D1 source pointer every time a word is copied*/

  uint32_t SRC_PTR_INC_D2;                        /*!< Increment the D2 source pointer every time a word is copied*/

  uint32_t DST_PTR_INC_D1;                        /*!< Increment the D1 destination pointer every time a word is copied*/

  uint32_t DST_PTR_INC_D2;                        /*!< Increment the D2 destination pointer every time a word is copied*/

  uint32_t SLOT;                                  /*!< The DMA will wait for the signal    connected to the selected trigger_slots to be high    on the read and write side respectively*/

  uint32_t SRC_DATA_TYPE;                         /*!< Width/type of the source data to transfer*/

  uint32_t DST_DATA_TYPE;                         /*!< Width/type of the destination data to transfer*/

  uint32_t SIGN_EXT;                              /*!< Is the data to be sign extended? (Checked only if the dst data type is wider than the src data type)*/

  uint32_t MODE;                                  /*!< Set the operational mode of the DMA*/

  uint32_t HW_FIFO_EN;                            /*!< Enable the HW FIFO mode*/

  uint32_t DIM_CONFIG;                            /*!< Set the dimensionality of the DMA*/

  uint32_t DIM_INV;                               /*!< DMA dimensionality inversion selector*/

  uint32_t PAD_TOP;                               /*!< Set the top padding*/

  uint32_t PAD_BOTTOM;                            /*!< Set the bottom padding*/

  uint32_t PAD_RIGHT;                             /*!< Set the right padding*/

  uint32_t PAD_LEFT;                              /*!< Set the left padding*/

  uint32_t WINDOW_SIZE;                           /*!< Will trigger a every "WINDOW_SIZE" writes    Set to 0 to disable.*/

  uint32_t WINDOW_COUNT;                          /*!< Number of times the end of the window was reached since the beginning.    Reset at start*/

  uint32_t INTERRUPT_EN;                          /*!< Interrupt Enable Register    (Only the interrupt with the lowest id will be triggered)*/

  uint32_t TRANSACTION_IFR;                       /*!< Interrupt Flag Register for transactions*/

  uint32_t WINDOW_IFR;                            /*!< Interrupt Flag Register for windows*/

} dma;

/****************************************************************************/
/**                                                                        **/
/**                          EXPORTED VARIABLES                            **/
/**                                                                        **/
/****************************************************************************/

#ifndef _DMA_STRUCTS_C_SRC



#endif  /* _DMA_STRUCTS_C_SRC */

/****************************************************************************/
/**                                                                        **/
/**                          EXPORTED FUNCTIONS                            **/
/**                                                                        **/
/****************************************************************************/


/****************************************************************************/
/**                                                                        **/
/**                          INLINE FUNCTIONS                              **/
/**                                                                        **/
/****************************************************************************/



#endif /* _DMA_STRUCTS_H */
/****************************************************************************/
/**                                                                        **/
/**                                EOF                                     **/
/**                                                                        **/
/****************************************************************************/
