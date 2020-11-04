`ifndef __JVS_PKG_SV__
 `define __JVS_PKG_SV__
`include "jvs_defines.sv"
`include "jvs_interfaces.sv"
`ifndef JVS_PKG_TIMEPRECISION
 `define JVS_PKG_TIMEPRECISION 1ps
`endif
package jvs_pkg;
   timeunit 1ns;
   timeprecision `JVS_PKG_TIMEPRECISION;
   import uvm_pkg::*;
`include "uvm_macros.svh"
`include "jvs_files.sv"
endpackage

`endif