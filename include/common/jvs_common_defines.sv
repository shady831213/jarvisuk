`ifndef __JVS_COMMON_DEFINES_SV__
 `define __JVS_COMMON_DEFINES_SV__

 `define JVS_WAVE(HIER) \
function string get_wave_name(); \
   string wave_name; \
   if ($test$plusargs("WAVE_NAME")) begin \
      void'($value$plusargs("WAVE_NAME=%s", wave_name)); \
   end \
   else begin \
      wave_name = "test"; \
   end \
   return wave_name; \
endfunction \
initial begin \
 `ifdef DUMP_FSDB \
  `ifndef GATE_SIM \
    $fsdbDumpfile($psprintf("%s.fsdb", get_wave_name())); \
  `else \
   $fsdbDumpfile($psprintf("%s_gate.fsdb", get_wave_name())); \
  `endif \
   $fsdbDumpvars(0, HIER, "+all"); \
  `ifdef DUMP_MEM \
    $fsdbDumpMDA; \
  `endif \
  `ifdef DUMP_SVA \
    $fsdbDumpSVA; \
  `endif \
   $fsdbDumpon; \
 `elsif DUMP_VPD \
  `ifndef GATE_SIM \
    $vcdplusfile($psprintf("%s.vpd", get_wave_name())); \
  `else \
   $vcdplusfile($psprintf("%s_gate.vpd", get_wave_name())); \
  `endif \
   $vcdpluson(0, HIER); \
 `elsif DUMP_VCD \
  `ifndef GATE_SIM \
    $dumpfile("test.vcd"); //cadence does not support string var\
  `else \
    $dumpfile("test_gate.vcd"); \
  `endif \
   $dumpvars(0, HIER); \
 `elsif DUMP_TRN \
  `ifndef GATE_SIM \
    $recordfile($psprintf("%s", get_wave_name())); \
  `else \
    $recordfile($psprintf("%s_gate", get_wave_name())); \
  `endif \
   $recordvars(0, HIER); \
 `endif \
end

 `define JVS_FOR_FJ_BEGIN(ID, LOW, HIGH, STEP) \
fork begin \
   for(int _i = LOW; _i < HIGH; _i = _i + STEP) begin \
      automatic int ID = _i; \
      fork \
         begin

`define JVS_FOR_FJ_END \
         end \
      join_none \
   end \
   wait fork; \
end \
join

   
 `define JVS_FOREACH_FJ_BEGIN(VAR, ID) \
fork begin \
   foreach(VAR[_i]) begin \
      automatic int ID = _i; \
      fork \
         begin

 `define JVS_FOREACH_FJ_END `JVS_FOR_FJ_END
 
`endif