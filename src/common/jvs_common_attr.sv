`ifndef __JVS_COMMON_ATTR_SV__
 `define __JVS_COMMON_ATTR_SV__
virtual class jvs_common_attr extends uvm_object;
   `uvm_field_utils_begin(jvs_common_attr)
   `uvm_field_utils_end

   function new(input string name = "jvs_common_attr");
      super.new(name);
   endfunction // new
endclass

`endif