`ifndef __JVS_IRQ_SEQUENCER_SV__
 `define __JVS_IRQ_SEQUENCER_SV__
typedef jvs_common_type_queue#(jvs_irq_handler) jvs_irq_handler_queue;
class jvs_irq_vir_sequencer extends uvm_virtual_sequencer;
   jvs_irq_handler_queue irq_table[bit[`JVS_MAX_IRQ_VECTOR_WIDTH-1:0]];

   uvm_analysis_imp#(jvs_irq_trans, jvs_irq_vir_sequencer) irq_put_imp;
   local uvm_tlm_analysis_fifo #(jvs_irq_trans) irq_fifo;

   `uvm_component_utils(jvs_irq_vir_sequencer)
   function new(string name = "jvs_irq_vir_sequencer", uvm_component parent = null);
      super.new(name, parent);
      irq_put_imp = new("irq_put_imp", this);
      irq_fifo = new("irq_fifo", this);
   endfunction // new

   function void write(jvs_irq_trans tr);
      if (irq_fifo == null) begin
	 tr.end_tr();
	 return;
      end
      irq_fifo.write(tr);
   endfunction // write

   task get_irq(output jvs_irq_trans tr);
      wait(irq_fifo != null);
      irq_fifo.get(tr);
   endtask // get_irq

   task register_irq(bit[`JVS_MAX_IRQ_VECTOR_WIDTH-1:0] irq_vector, jvs_irq_handler handler);
      if (!irq_table.exists(irq_vector) || irq_table[irq_vector] == null) begin
	 irq_table[irq_vector] = new();
      end
      irq_table[irq_vector].lock.get(1);
      irq_table[irq_vector].queue.push_back(handler);
      irq_table[irq_vector].lock.put(1);
   endtask // register_irq

   task unregister_irq(bit[`JVS_MAX_IRQ_VECTOR_WIDTH-1:0] irq_vector, jvs_irq_handler handler);
      irq_table[irq_vector].lock.get(1);
      foreach(irq_table[irq_vector].queue[i]) begin
	 if (irq_table[irq_vector].queue[i] == handler) begin
	    irq_table[irq_vector].queue.delete(i);
	    break;
	 end
      end
      irq_table[irq_vector].lock.put(1);
   endtask // unregister_irq

   virtual task reset();
      //clear fifo
      irq_fifo = null;
      //clear irq_table
      foreach(irq_table[i]) begin
	 if (irq_table[i] != null) begin
	    irq_table[i].lock.get(1);
	    irq_table[i] = null;
	    irq_table[i].lock.put(1);
	 end
      end
      //start fifo
      irq_fifo = new("irq_fifo", this);
   endtask
endclass
`endif