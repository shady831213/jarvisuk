`ifndef __JVS_IRQ_TRANS_SV__
 `define __JVS_IRQ_TRANS_SV__
typedef jvs_common_attr jvs_irq_trans_attr;

virtual class jvs_irq_result_trans_data extends uvm_object;
   `uvm_field_utils_begin(jvs_irq_result_trans_data)
   `uvm_field_utils_end
   function new (string name = "jvs_irq_result_trans_data");
      super.new(name);
   endfunction
endclass // jvs_irq_result_trans_data

/*
 irq_vecotr[`JVS_MAX_IRQ_VECTOR_WIDTH-1:`JVS_MAX_IRQ_VECTOR_WIDTH-2]
 00: int_irq
 01: msi_irq
 10: soft_irq/exception
 11: unsupport type
 */

virtual class jvs_irq_trans_base extends uvm_sequence_item;
   typedef enum {INT_IRQ,
		 MSI_IRQ,
		 SOFT_IRQ} irq_type_e;
   rand bit [`JVS_MAX_IRQ_VECTOR_WIDTH-1:0] irq_vector;
   `uvm_field_utils_begin(jvs_irq_trans_base)
      `uvm_field_int(irq_vector, UVM_ALL_ON)
   `uvm_field_utils_end

   function new(string name = "jvs_irq_trans_base");
      super.new(name);
   endfunction // new

   function irq_type_e get_irq_type();
      case(irq_vector[`JVS_MAX_IRQ_VECTOR_WIDTH-1:`JVS_MAX_IRQ_VECTOR_WIDTH-2])
	`JVS_INT_IRQ_FLAG: return INT_IRQ;
	`JVS_MSI_IRQ_FLAG: return MSI_IRQ;
	`JVS_SOFT_IRQ_FLAG: return SOFT_IRQ;
      endcase
   endfunction // get_irq_type

endclass // jvs_irq_trans_base

/*
 UNHANDLED: bypass this irq
 THROUGH: handled and pass to other handlers shared the same vector
 FINISH: handled as end point
 redirected: has benn redirected to other vecotr
 */

class jvs_irq_trans extends jvs_irq_trans_base;
   typedef enum {UNHANDLED,
		 THROUGH,
		 FINISH
		 } irq_handle_state_e;
   irq_handle_state_e handle_state;
   protected jvs_irq_trans pre_irq_trans;
   protected jvs_irq_trans redirected_trans[$];
   jvs_irq_trans_attr attr;

   `uvm_object_utils_begin(jvs_irq_trans);
      `uvm_field_object(attr, UVM_ALL_ON)
      `uvm_field_object(pre_irq_trans, UVM_ALL_ON| UVM_REFERENCE | UVM_NOCOPY)
      `uvm_field_enum(irq_handle_state_e, handle_state, UVM_ALL_ON | UVM_NOCOPY)
      `uvm_field_queue_object(redirected_trans, UVM_ALL_ON | UVM_NOCOPY)
   `uvm_object_utils_end

   function new(string name = "jvs_irq_trans");
      super.new(name);
      handle_state = UNHANDLED;
   endfunction // new

   function jvs_irq_trans redirect([`JVS_MAX_IRQ_VECTOR_WIDTH - 1:0] irq_vector);
      jvs_irq_trans redirect_trans = jvs_irq_trans::type_id::create({"redirect_", this.get_name()});
      redirect_trans.copy(this);
      redirect_trans.irq_vector = irq_vector;
      redirect_trans.pre_irq_trans = this;
      redirected_trans.push_back(redirect_trans);
      return redirect_trans;
   endfunction // redirect

   function bit is_redirected();
      return redirected_trans.size() > 0;
   endfunction
   
   //only when all redirected_trans can_end_tr and self is in FINISH state
   function bit can_end_tr();
      bit 	redirected_trans_all_done = 1;
      foreach(redirected_trans[i]) begin
	 redirected_trans_all_done = redirected_trans_all_done & redirected_trans[i].can_end_tr();
      end
      return redirected_trans_all_done && handle_state == FINISH;
   endfunction // can_end_tr

   //the last ended redirected_trans ends pre_irq_trans
   virtual function void do_end_tr();
      if (pre_irq_trans != null && pre_irq_trans.is_redirected() && pre_irq_trans.can_end_tr()) begin
	 pre_irq_trans.end_tr();
      end
   endfunction // do_end_tr

   function jvs_irq_trans get_root_irq_source();
      return pre_irq_trans == null ? this : pre_irq_trans.get_root_irq_source();
   endfunction
endclass // jvs_irq_trans

class jvs_irq_result_trans extends jvs_irq_trans_base;
   jvs_irq_result_trans_data data;
   `uvm_object_utils_begin(jvs_irq_result_trans)
     `uvm_field_object(data, UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name = "jvs_irq_result_trans");
      super.new(name);
   endfunction	
endclass
`endif