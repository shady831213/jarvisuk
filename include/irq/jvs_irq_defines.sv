`ifndef __JVS_IRQ_DEFINES_SV__
 `define __JVS_IRQ_DEFINES_SV__
 `ifndef JVS_MAX_INT_PIN_NUM
  `define JVS_MAX_INT_PIN_NUM 1024
 `endif

// Keep the legacy factory name for the default specialization. Other widths
// register by type, as with uvm_component_param_utils.
`define JVS_PIN_COMPONENT_UTILS(T) \
   localparam string type_name = PIN_COUNT == `JVS_MAX_INT_PIN_NUM ? `"T`" : "<unknown>"; \
   typedef uvm_component_registry #(T #(PIN_COUNT), type_name) type_id; \
   static function type_id get_type(); return type_id::get(); endfunction \
   virtual function uvm_object_wrapper get_object_type(); return type_id::get(); endfunction \
   virtual function string get_type_name(); \
      return PIN_COUNT == `JVS_MAX_INT_PIN_NUM ? `"T`" : $sformatf("%s#(%0d)", `"T`", PIN_COUNT); \
   endfunction

 `ifndef JVS_MAX_IRQ_VECTOR_WIDTH
  `define JVS_MAX_IRQ_VECTOR_WIDTH 64
 `endif

`define JVS_INT_IRQ_FLAG 2'b00
`define JVS_MSI_IRQ_FLAG 2'b01
`define JVS_SOFT_IRQ_FLAG 2'b10
`define JVS_UNDEFINED_IRQ_FLAG 2'b11

`define JVS_INT_IRQ_V(x) ((x) & {(`JVS_MAX_IRQ_VECTOR_WIDTH-2){1'b1}} | {`JVS_INT_IRQ_FLAG, {(`JVS_MAX_IRQ_VECTOR_WIDTH-2){1'b0}}})
`define JVS_MSI_IRQ_V(x) ((x) & {(`JVS_MAX_IRQ_VECTOR_WIDTH-2){1'b1}} | {`JVS_MSI_IRQ_FLAG, {(`JVS_MAX_IRQ_VECTOR_WIDTH-2){1'b0}}})
`define JVS_SOFT_IRQ_V(x) ((x) & {(`JVS_MAX_IRQ_VECTOR_WIDTH-2){1'b1}} | {`JVS_SOFT_IRQ_FLAG, {(`JVS_MAX_IRQ_VECTOR_WIDTH-2){1'b0}}})

`endif
