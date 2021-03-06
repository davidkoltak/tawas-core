# TCL File Generated by Component Editor 18.0
# Thu Sep 20 16:12:13 CDT 2018
# DO NOT MODIFY

# SPDX-License-Identifier: MIT
# (c) Copyright 2018 David M. Koltak, all rights reserved.

#
# debug_lsa "debug_lsa" v1.0
#  2018.09.20.16:12:13
#
#

#
# request TCL package from ACDS 18.0
#
package require -exact qsys 18.0


#
# module debug_lsa
#
set_module_property DESCRIPTION ""
set_module_property NAME debug_lsa
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME debug_lsa
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


#
# file sets
#
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL debug_lsa
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file debug_lsa.v VERILOG PATH debug_lsa.v TOP_LEVEL_FILE


#
# parameters
#


#
# display items
#


#
# connection point av
#
add_interface av avalon end
set_interface_property av addressGroup 0
set_interface_property av addressUnits WORDS
set_interface_property av associatedClock av_clk
set_interface_property av associatedReset av_reset
set_interface_property av bitsPerSymbol 8
set_interface_property av bridgedAddressOffset ""
set_interface_property av bridgesToMaster ""
set_interface_property av burstOnBurstBoundariesOnly false
set_interface_property av burstcountUnits WORDS
set_interface_property av explicitAddressSpan 0
set_interface_property av holdTime 0
set_interface_property av linewrapBursts false
set_interface_property av maximumPendingReadTransactions 1
set_interface_property av maximumPendingWriteTransactions 0
set_interface_property av minimumResponseLatency 1
set_interface_property av readLatency 0
set_interface_property av readWaitTime 1
set_interface_property av setupTime 0
set_interface_property av timingUnits Cycles
set_interface_property av transparentBridge false
set_interface_property av waitrequestAllowance 0
set_interface_property av writeWaitTime 0
set_interface_property av ENABLED true
set_interface_property av EXPORT_OF ""
set_interface_property av PORT_NAME_MAP ""
set_interface_property av CMSIS_SVD_VARIABLES ""
set_interface_property av SVD_ADDRESS_GROUP ""

add_interface_port av av_address address Input 10
add_interface_port av av_write write Input 1
add_interface_port av av_read read Input 1
add_interface_port av av_writedata writedata Input 32
add_interface_port av av_readdata readdata Output 32
add_interface_port av av_readdatavalid readdatavalid Output 1
set_interface_assignment av embeddedsw.configuration.isFlash 0
set_interface_assignment av embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment av embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment av embeddedsw.configuration.isPrintableDevice 0


#
# connection point av_clk
#
add_interface av_clk clock end
set_interface_property av_clk ENABLED true
set_interface_property av_clk EXPORT_OF ""
set_interface_property av_clk PORT_NAME_MAP ""
set_interface_property av_clk CMSIS_SVD_VARIABLES ""
set_interface_property av_clk SVD_ADDRESS_GROUP ""

add_interface_port av_clk av_clk clk Input 1


#
# connection point av_reset
#
add_interface av_reset reset end
set_interface_property av_reset associatedClock av_clk
set_interface_property av_reset synchronousEdges DEASSERT
set_interface_property av_reset ENABLED true
set_interface_property av_reset EXPORT_OF ""
set_interface_property av_reset PORT_NAME_MAP ""
set_interface_property av_reset CMSIS_SVD_VARIABLES ""
set_interface_property av_reset SVD_ADDRESS_GROUP ""

add_interface_port av_reset av_rst reset Input 1


#
# connection point debug_lsa
#
add_interface debug_lsa conduit end
set_interface_property debug_lsa associatedClock ""
set_interface_property debug_lsa associatedReset ""
set_interface_property debug_lsa ENABLED true
set_interface_property debug_lsa EXPORT_OF ""
set_interface_property debug_lsa PORT_NAME_MAP ""
set_interface_property debug_lsa CMSIS_SVD_VARIABLES ""
set_interface_property debug_lsa SVD_ADDRESS_GROUP ""

add_interface_port debug_lsa lsa_mode lsa_mode Output 8
add_interface_port debug_lsa lsa_clk lsa_clk Input 1
add_interface_port debug_lsa lsa_trigger lsa_trigger Input 1
add_interface_port debug_lsa lsa_data lsa_data Input 32

