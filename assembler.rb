#! /user/bin/env ruby

DATA_BITS = 32
ADDRESSES = 2048

# Store register name/number as key/value pair
register_hash = { "zero" => 0b00000, "a0" => 0b00001, "a1" => 0b00010, "a2" => 0b00011, "a3" => 0b00100,
                  "r5" => 0b00101, "r6" => 0b00110, "r7" => 0b00111, "t0" => 0b01000, "t1" => 0b01001,
                  "t2" => 0b01010, "t3" => 0b01011, "t4" => 0b01100, "t5" => 0b01101, "t6" => 0b01110,
                  "t7" => 0b01111, "s0" => 0b10000, "s1" => 0b10001, "s2" => 0b10010, "s3" => 0b10011,
                  "s4" => 0b10100, "s5" => 0b10101, "s6" => 0b10110, "s7" => 0b10111, "r24" => 0b11000,
                  "r25" => 0b11001, "r26" => 0b11010, "r27" => 0b11011, "r28" => 0b11100, "r29" => 0b11101,
                  "r30" => 0b11110,"r31" => 0b11111
                  }

# Store insruction/opcode1 as key/value pair
opcode1_hash = { "alur" => 0b000000, "andi" => 0b000001, "ori" => 0b000010, "hi" => 0b000011,
                 "addi" => 0b000100, "lw" => 0b010000, "sw" => 0b010001, "jal" => 0b100000,
                 "beq" => 0b100001, "bne" => 0b100101
               }

# Store instruction/opcode2 as key/value pair
opcode2_hash = {  "and" => 0b000001, "or" => 0b000010, "xor" => 0b000011, "nand" => 0b000101,
                  "nor" => 0b000110, "nxor" => 0b000111, "add" => 0b010000, "sub" => 0b010001,
                  "eq" => 0b100001, "lt" => 0b100010, "le" => 0b100011, "ne" => 0b100101,
                  "ge" => 0b100110, "gt" => 0b100111
               }

pseudo_inst = ["subi", "not", "br", "blt", "ble", "bgt", "bge", "call", "jmp", "ret"]
# Hash to store any declared name/address as key/value pair
name_hash = {}

# hash to store code section names and line numbers
section_hash = {}

#make sure a valid .a32 file was specified
if ARGV.length==1
  source_file = ARGV.first
  file_specified = true
else
  puts "Invalid command. Use 'ruby assembler.rb filename.a32' to specify file"
  file_specified = false
end

#Check that the specified file actually exists
if(file_specified)
  if(!File.exist?(source_file))
    puts "Invalid file name. Please enter valid .a32 file for assembly"
    file_exists = false
  else
    #TODO check for .a32 file extension
    file_exists = true
  end
end

#Parse the file and assemble the .mif file
if(file_specified && file_exists)
  puts "Starting assembly"

  #create the .mif file to send the output of the assembly
  file_name = source_file.split('.')[0]
  output_file_name = [file_name, "mif"].join('.')
  puts "Creating output file: #{output_file_name}"

  #TODO check if output file already exists
  output_file = File.new(output_file_name, "w")

  #open the specified .a32 file for reading for first pass
  input_file = File.open(source_file, "r")

  # regex to match the NAME keyword
  name_regex = /NAME/

  # FIRST PASS -> extract name variables
  while (line = input_file.gets)
    # Check if the line contains a .NAME
    if line =~ name_regex
      # Extract the new name/address pair and remove excess white space
      name_line = line[5..-1].strip
      temp_name_var, temp_name_val = name_line.split('=')
      name_var = temp_name_var.strip
      name_val = temp_name_val.strip
      name_hash[name_var] = name_val
    end
  end
  # END OF FIRST PASS

  # set the input back to the beginning of input_file
  input_file.rewind

  # regex to match code sections, and pseudo instructions
  section_regex = /[a-zA-Z]:/
  #pseudo_regex = //

  line_cnt = 0
  # SECOND PASS ->
  while (line = input_file.gets)
    #Check if the line indicates a new code section
    num = line =~ section_regex
    if num
      sec_name = line[0..num]
      section_hash[sec_name] = line_cnt
    end

    #check if the line is an instruction
    

    
  end


  #Close both input and output file
  input_file.close
  output_file.close
end
