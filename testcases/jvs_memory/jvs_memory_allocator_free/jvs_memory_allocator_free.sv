`ifndef __JVS_MEMORY_ALLOCATOR_FREE_SV__
`define __JVS_MEMORY_ALLOCATOR_FREE_SV__
`include "uvm_macros.svh"
import uvm_pkg::*;
import jvs_pkg::*;

// Exercise the public allocator against fixed addresses and live data, without
// inspecting its private allocated/free queues.
class jvs_memory_allocator_free extends uvm_test;
   `uvm_component_utils(jvs_memory_allocator_free)
   localparam bit [63:0] BASE = 64'h1000;
   localparam bit [63:0] HEAP_BYTES = 256;
   jvs_memory_allocator allocator;

   function new(string name="jvs_memory_allocator_free", uvm_component parent=null);
      super.new(name, parent);
   endfunction

   task allocate_at(ref jvs_memory_acc_block block, input bit [63:0] address, input bit [63:0] size);
      allocator.malloc(block, size, ALIGN_BYTE, {1'b0, address});
      if (block == null) `uvm_fatal("FREE_REUSE", "A released interval could not be allocated")
      if (block.get_s_addr() != address || block.get_size() != size)
         `uvm_fatal("FREE_GEOMETRY", "Allocation changed requested geometry")
   endtask

   task reject_at(bit [63:0] address);
      jvs_memory_acc_block block;
      allocator.malloc(block, 1, ALIGN_BYTE, {1'b0, address});
      if (block != null) `uvm_fatal("FREE_INVALID_RANGE", "Allocated a live or outside-heap address")
   endtask

   task reclaim_heap();
      jvs_memory_acc_block block;
      repeat (2) begin
         allocate_at(block, BASE, HEAP_BYTES);
         reject_at(BASE);
         allocator.free(block);
         if (block != null) `uvm_fatal("FREE_HANDLE", "free did not clear the caller's handle")
      end
   endtask

   task exercise(int scenario);
      jvs_memory_cfg cfg = new("cfg");
      jvs_memory_acc_block first, second, replacement;
      bit [63:0] block_bytes = scenario == 3 ? HEAP_BYTES / 2 : 32;
      cfg.range = new("range");
      cfg.range.configurate(BASE, HEAP_BYTES);
      cfg.model = jvs_memory_aa_model::type_id::create("model");
      allocator = new("allocator");
      allocator.configurate(cfg);
      allocate_at(first, BASE, block_bytes);
      first.write_byte(0, 8'ha5);
      if (scenario != 2) begin
         allocate_at(second, BASE + block_bytes, block_bytes);
         second.write_byte(0, 8'h5a);
      end
      case (scenario)
         0: begin // A live lower neighbour must never become part of free space.
            allocator.free(second);
            reject_at(BASE);
            if (first.read_byte(0) != 8'ha5) `uvm_fatal("FREE_LIVE_DATA", "free damaged a live neighbour")
            allocate_at(replacement, BASE + block_bytes, block_bytes);
            allocator.free(replacement);
            allocator.free(first);
         end
         1: begin // No lower neighbour; the upper allocation remains live.
            allocator.free(first);
            reject_at(BASE + block_bytes);
            reject_at(0);
            if (second.read_byte(0) != 8'h5a) `uvm_fatal("FREE_LIVE_DATA", "free damaged a live neighbour")
            allocate_at(replacement, BASE, block_bytes);
            allocator.free(replacement);
            allocator.free(second);
         end
         2: begin // A free upper neighbour must merge with an initialized interval.
            allocator.free(first);
            reject_at(0);
         end
         3: begin // Empty free queue and subsequent two-sided reclamation.
            allocator.free(first);
            reject_at(BASE + block_bytes);
            allocate_at(replacement, BASE, block_bytes);
            allocator.free(second);
            reject_at(BASE);
            allocator.free(replacement);
         end
         default: `uvm_fatal("FREE_CASE", "Unknown allocator regression case")
      endcase
      reject_at(0);
      reject_at(BASE + HEAP_BYTES);
      reclaim_heap();
      $display("JVS_ALLOCATOR_FREE_PASS case=%0d", scenario);
   endtask

   task run_phase(uvm_phase phase);
      int scenario;
      phase.raise_objection(this);
      if ($value$plusargs("JVS_FREE_CASE=%d", scenario)) exercise(scenario);
      else for (int i=0; i<4; i++) exercise(i);
      phase.drop_objection(this);
   endtask
endclass
`endif
