## Scripts
#### ` iitb-risc-simulator.php ` 
- It implements the programmer's model of IITB-RISC ISA. program is read in the form of assembly code. 

- After every instruction, values of updated state elements (registers and memory locations) is echoed.
    
- The number of instructions to be executed is to be given as a command line argument, along with path to program file.
   
      php iitb-risc-simulator.php 4 <path-to-program.txt>

- Note: The simulator assumes correctness of syntax of assembly code provided.