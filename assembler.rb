#! /user/bin/env ruby

DATA_BITS = 32
ADDRESSES = 2048

# Store register name/number as key/value pair
register_hash = { "zero" => "00000", "a0" => "00001", "a1" => "00010", "a2" => "00011", "a3" => "00100",
                  "r5" => "00101", "r6" => "00110", "r7" => "00111", "t0" => "01000", "t1" => "01001",
                  "t2" => "01010", "t3" => "01011", "t4" => "01100", "t5" => "01101", "t6" => "01110",
                  "t7" => "01111", "s0" => "10000", "s1" => "10001", "s2" => "10010", "s3" => "10011",
                  "s4" => "10100", "s5" => "10101", "s6" => "10110", "s7" => "10111", "r24" => "11000",
                  "r25" => "11001", "r26" => "11010", "r27" => "11011", "r28" => "11100", "r29" => "11101",
                  "r30" => "11110","r31" => "11111"
                  }

# Store insruction/opcode1 as key/value pair
opcode1_hash = { "alur" => "000000", "andi" => "000001", "ori" => "000010", "hi" => "000011",
                 "addi" => "000100", "lw" => "010000", "sw" => "010001", "jal" => "100000",
                 "beq" => "100001", "bne" => "100101"
               }

# Store instruction/opcode2 as key/value pair
#TODO change opcode values to match those in the test file
opcode2_hash = {  "and" => "001001", "or" => "001010", "xor" => "001011", "nand" => "001101",
                  "nor" => "001110", "nxor" => "001111", "add" => "010000", "sub" => "010001",
                  "eq" => "100001", "lt" => "100010", "le" => "100011", "ne" => "100101",
                  "ge" => "100110", "gt" => "100111", "noop" => "000000"
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

  output_file = File.new(output_file_name, "w")

  #Put the file headers in the output file
  output_file.puts "WIDTH=#{DATA_BITS};"
  output_file.puts "DEPTH=#{ADDRESSES};"
  output_file.puts "ADDRESS_RADIX=HEX;"
  output_file.puts "DATA_RADIX=HEX;"
  output_file.puts "CONTENT BEGIN"

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
      name_var = temp_name_var.strip.downcase
      name_val = temp_name_val.strip.split('0x')[1]
      name_hash[name_var] = name_val
    end
  end
  # END OF FIRST PASS

#  name_hash.each do |name, val|
#    puts "Name: #{name}, Value: #{val}"
#  end

  # set the input back to the beginning of input_file
  input_file.rewind

  # regex to match various parts of the code that must be handled differently
  section_regex = /[a-zA-Z0-9]+:/
  inst_regex = /\s([a-zA-Z]+)/
  orig_regex = /ORIG/
  comment_regex = /^\s+;/

  #Create new .a32 file that has no pseudo instructions
  temp_src = File.new("temp.a32", "w")

  # SECOND PASS -> replace pseudo instructions in temp.a32 file
  while (line = input_file.gets)

    # variable indicating whether or not to write the unmodified line to temp.a32
    write = true

    #Check if the line contains a pseudo instruction
    if is_inst = line =~ inst_regex
      inst_name = inst_regex.match(line)[1].strip.downcase
      if index = pseudo_inst.index(inst_name)
        write = false
        opcode, regs = line.split("\s")
        if regs
          regs_arr = regs.split(",")
        end
#        puts "Instruction: #{inst_name}, Regs Arr: #{regs_arr}"
        # Find out which instruction it is, and replace it with real instructions
        case inst_name
        when "subi"
          new_imm = ((regs_arr[2].to_i)*-1).to_s
          new_regs = [regs_arr[0], regs_arr[1], new_imm].join(',')
          out_line = ["\taddi", new_regs].join(' ')
        when "not"
          new_regs = [regs_arr[0], regs_arr[1], regs_arr[1]].join(',')
          out_line = ["\tnor", new_regs].join(' ')
        when "br"
          new_regs = ["zero","zero",regs_arr[0]].join(',')
          out_line = ["\tbeq", new_regs].join(' ')
        when "blt"
          #Need to insert 2 instructions
          new_regs = ["r6", regs_arr[0], regs_arr[1]].join(',')
          out_line = ["\tlt", new_regs].join(' ')
          temp_src.puts out_line

          new_regs = ["r6", "zero", regs_arr[2]].join(',')
          out_line = ["\tbne", new_regs].join(' ')
        when "ble"
          new_regs = ["r6", regs_arr[0], regs_arr[1]].join(',')
          out_line = ["\tle", new_regs].join(' ')
          temp_src.puts out_line

          new_regs = ["r6", "zero", regs_arr[2]].join(',')
          out_line = ["\tbne", new_regs].join(' ')
        when "bgt"
          new_regs = ["r6", regs_arr[0], regs_arr[1]].join(',')
          out_line = ["\tgt", new_regs].join(' ')
          temp_src.puts out_line

          new_regs = ["r6", "zero", regs_arr[2]].join(',')
          out_line = ["\tbne", new_regs].join(' ')
        when "bge"
          new_regs = ["r6", regs_arr[0], regs_arr[1]].join(',')
          out_line = ["\tge", new_regs].join(' ')
          temp_src.puts out_line

          new_regs = ["r6", "zero", regs_arr[2]].join(',')
          out_line = ["\tbne", new_regs].join(' ')
        when "call"
          new_regs = ["ra", regs_arr[0]].join(',')
          out_line = ["\tjal", new_regs].join(' ')
        when "jmp"
          new_regs = ["r6", regs_arr[0]].join(',')
          out_line = ["\tjal", new_regs].join(' ')
        when "ret"
          out_line = "\tjal r6,0(ra)"
        end
      end
    end

    if write
      temp_src.puts line
    else
      temp_src.puts out_line
    end
  end

  # close input_file adn temp_src
  input_file.close
  temp_src.close

  input_file = File.open("temp.a32", "r")
  #current memory address needed for output file
  current_addr = 0
  #line_count
  line_cnt = 0

  #THIRD PASS set up the section hash and their memory addresses
  while (line = input_file.gets)
    #TODO change value stored in section_hash to make calculation of imm values easier
    section_line = line_cnt

    if line =~ orig_regex
      orig, mem_addr = line.split(' ')
      if mem_addr =~ /0x/
        new_cnt = (mem_addr.to_i(16))/4
      else
        new_cnt = mem_addr.to_i
      end
      line_cnt = new_cnt
    end

    #Check if the line indicates a new code section
    if is_section = line =~ section_regex
      sec_name = section_regex.match(line)[0]
      if sec_name
        section_hash[sec_name[0..-2].downcase] = section_line
      end
      next
    end

    if is_inst = line =~ inst_regex
      inst_name = inst_regex.match(line)[1].strip.downcase

      if opcode1_hash[inst_name] || opcode2_hash[inst_name] || pseudo_inst.index(inst_name)
        line_cnt+=1
      end
    end
  end
  input_file.close
  #END OF THIRD PASS

#  section_hash.each do |name, value|
#    puts "section name: #{name}, value: #{value}"
#  end


  input_file = File.open("temp.a32", "r")

  #current memory address needed for output file
  current_addr = 0
  #line_count
  line_cnt = 0
  # FINAL PASS
  while (line = input_file.gets)
    #variables to make the output strings more easily
    dashes = "--"
    at = "@"
    hex = "0x"
    line_hex = (line_cnt*4).to_s(16)
    line_hex = hex + ("0" * (8-line_hex.length)) + line_hex
    code_hex = line_cnt.to_s(16)
    code_hex = ("0" * (8-code_hex.length)) + code_hex
    section_hex = (line_cnt*4).to_s(16)
    section_hex = ("0" * (8-section_hex.length)) + section_hex

    inst_var, comment = line.split(";")

    # String that contains the memory location and the instruction
    inst_string = [dashes, at, line_hex, ":", inst_var].join(' ')

    data_string = [code_hex, " : "].join

    # check if the line is a comment
    if line =~ comment_regex
      next
    end

    # check if the line has the NAME keyword
    if line =~ name_regex
      next
    end

    # Check for the ORIG keyword to set the line_cnt var
    if line =~ orig_regex
      orig, mem_addr = line.split(' ')
      #TODO figure out where new line_hex and code hex are, and where 0xDEAD mem addresses are
      if mem_addr =~ /0x/
        new_cnt = (mem_addr.to_i(16))/4
      else
        new_cnt = mem_addr.to_i
      end

      # make memory between line_cnt and new_cnt 0xDEAD
      if (new_cnt-line_cnt) > 1
        low_mem = line_cnt
        high_mem = new_cnt-1
        #Insert 0xDEAD into empty memory
        low_str = low_mem.to_s
        low_str = ("0" * (8-low_str.length)) + low_str
        high_str = high_mem.to_s
        high_str = ("0" * (8-high_str.length)) + high_str
        dead_str = ["[", low_str, "..", high_str, "] : DEAD;"].join
        output_file.puts dead_str

        #set line_cnt to new_cnt
        line_cnt = new_cnt
      end

      next
    end

    #check if the line is an instruction
    if is_inst = line =~ inst_regex
      inst_name = inst_regex.match(line)[1].strip.downcase

      # variable to indicate whether or not to write to the output file
      write = false

      if opcode1_hash[inst_name]
        # instruction is a primary opcode
        opcode, regs = line.split("\s")
        opcode = opcode.strip.downcase
        code_str = opcode1_hash[opcode]
        data_bin = code_str

        #Parse the registers
        regs = regs.split(",")

        #Check if instruction is I-type opcode
        itype = ["andi", "ori", "addi", "hi"]
        if itype.index(opcode)
          reg0 =  register_hash[regs[0].downcase]
          reg1 = register_hash[regs[1].downcase]
          imm_val = regs[2]

          if section_hash[imm_val.downcase]
            imm_val = section_hash[imm_val.downcase] * 4
            if imm_val < 0
              imm_val = sprintf("%b", imm_val)[2..-1]
              if imm_val.length<16
                imm_val = ("1"*(16-imm_val.length))+imm_val
              end
              #Change the imm_val to hex
              hex0 = imm_val[0..3].to_i(2).to_s(16)
              hex1 = imm_val[4..7].to_i(2).to_s(16)
              hex2 = imm_val[8..11].to_i(2).to_s(16)
              hex3 = imm_val[12..15].to_i(2).to_s(16)
              imm_val = hex0+hex1+hex2+hex3
            else
              imm_val = imm_val.to_s(16)
              if imm_val.length<4
                imm_val = ("0" * (4-imm_val.length)) + imm_val
              end
            end
          elsif imm_val =~ /0x/
            #extract hex value
            imm_val = imm_val.split('0x')[1]
            if imm_val.length<4
              imm_val = ("0" * (4-imm_val.length)) + imm_val
            end
          elsif imm_val =~ /\-/
            imm_val = imm_val.to_i
            imm_val = sprintf("%b", imm_val)[2..-1]
            if imm_val.length<16
              imm_val = ("1"*(16-imm_val.length))+imm_val
            end
            #Change the imm_val to hex
            hex0 = imm_val[0..3].to_i(2).to_s(16)
            hex1 = imm_val[4..7].to_i(2).to_s(16)
            hex2 = imm_val[8..11].to_i(2).to_s(16)
            hex3 = imm_val[12..15].to_i(2).to_s(16)
            imm_val = hex0+hex1+hex2+hex3
          else
            imm_val = imm_val.to_i.to_s(16)
            if imm_val.length<4
              imm_val = ("0" * (4-imm_val.length)) + imm_val
            end
          end

          data_bin = [data_bin, reg1, reg0].join.to_i(2).to_s(16)
          data_bin += imm_val.to_s
        end

        mem_inst = ["lw", "sw"]
        if mem_inst.index(opcode)
          reg1 = register_hash[regs[0].downcase]
          imm_val = regs[1]
          addr, val = imm_val.split('(')
          val = val[0..-2]
          if register_hash[val]
            reg_code = register_hash[val]
          end
          imm_num = ""
          if name_hash[addr.downcase]
            imm_num = name_hash[addr.downcase][-4..-1]
          else
            #not a name keyword, must just be an integer
            if addr =~ /\-/
              imm_num = addr.to_i
              imm_num = sprintf("%b", imm_num)[2..-1]
              if imm_num.length<16
                imm_num = ("1"*(16-imm_num.length))+imm_num
              end
              #Change the imm_val to hex
              hex0 = imm_num[0..3].to_i(2).to_s(16)
              hex1 = imm_num[4..7].to_i(2).to_s(16)
              hex2 = imm_num[8..11].to_i(2).to_s(16)
              hex3 = imm_num[12..15].to_i(2).to_s(16)
              imm_num = hex0+hex1+hex2+hex3
            else
              #positive number
              imm_num = addr.to_i.to_s(2)
              if imm_num.length < 16
                imm_num = ("0" * (16-imm_num.length)) + imm_num
              elsif imm_num.length > 16
                imm_num = imm_num[-16..-1]
              end
              imm_num = imm_num.to_i(2).to_s(16)
              if imm_num.length<4
                imm_num = ("0" * (4-imm_num.length)) + imm_num
              end
            end
          end

          data_bin += [reg_code, reg1].join
          data_bin = data_bin.to_i(2).to_s(16)
          data_bin += imm_num
        end

        jumps = ["jal", "beq", "bne"]
        if jumps.index(opcode)
          if regs.size ==2
            reg0 = register_hash[regs[0].downcase]
            imm_val = regs[1]
            if imm_val =~ /\(/
              puts "Imm val: #{imm_val} line count: #{line_cnt}"
              # immediate value is of the form Imm(t0)
              temp = imm_val.split('(')
              reg1 = temp[1][0..-2].downcase
              reg1 = register_hash[reg1]
              imm_val = temp[0]
              if section_hash[imm_val.downcase]
                imm_val = section_hash[imm_val.downcase].to_s(16)
              end
              if imm_val.length<4
                imm_val = ("0" * (4-imm_val.length)) + imm_val
              end
            else
             reg0 = "00000"
            end
          elsif regs.size==3
            reg0 = register_hash[regs[0].downcase]
            reg1 = register_hash[regs[1].downcase]
            imm_val = regs[2]
          end
          if section_hash[imm_val.downcase]
            imm_val = section_hash[imm_val.downcase] - line_cnt - 1
            if imm_val < 0
              imm_val = sprintf("%b", imm_val)[2..-1]
              if imm_val.length<16
                imm_val = ("1"*(16-imm_val.length))+imm_val
              end
              #Change the imm_val to hex
              hex0 = imm_val[0..3].to_i(2).to_s(16)
              hex1 = imm_val[4..7].to_i(2).to_s(16)
              hex2 = imm_val[8..11].to_i(2).to_s(16)
              hex3 = imm_val[12..15].to_i(2).to_s(16)
              imm_val = hex0+hex1+hex2+hex3
            else
              imm_val = imm_val.to_s(16)
            end
          end
          #TODO Fix the immediate values added to the end of data_bin
          if imm_val.length<4
            imm_val = ("0"*(4-imm_val.length)) + imm_val
          end
          if jumps.index(opcode) > 0
            data_bin = [data_bin, reg0, reg1].join.to_i(2).to_s(16)
            data_bin += imm_val.to_s
          else
            data_bin  = [data_bin, reg1, reg0].join.to_i(2).to_s(16)
            data_bin += imm_val.to_s
          end
        end

        line_cnt+=1
        write = true
      end

      if opcode2_hash[inst_name]
        opcode, regs = line.split("\s")
        opcode = opcode.strip.downcase
        code_str = opcode2_hash[opcode]
        data_bin = opcode1_hash["alur"]

        regs = regs.split(",")
        reg_arr = Array.new
        regs.each do |name|
          reg_str = register_hash[name]
          if reg_str
            reg_arr << reg_str
          end
        end

        data_bin += [reg_arr[1], reg_arr[2], reg_arr[0]].join

        data_bin += "00000"
        data_bin += code_str

        data_bin = data_bin.to_i(2).to_s(16)
        line_cnt+=1
        write = true
      end

      if write
        #make the complete instruction in hex
        if data_bin.length<8
          data_bin = ("0" * (8-data_bin.length)) + data_bin
        end
        data_string += [data_bin.downcase, ";"].join
        output_file.puts inst_string
        output_file.puts data_string
      end
    end
  end

  #Mark ny unused memory addresses as DEAD
  max_mem = 2047
  max_str = max_mem.to_s(16)
  max_str = ("0" * (4-max_str.length)) + max_str
  code_hex = line_cnt.to_s(16)
  code_hex = ("0" * (4-code_hex.length)) + code_hex
  dead_line = "[#{code_hex}..#{max_str}] : DEAD;"
  output_file.puts dead_line
  end_line = "END;"
  output_file.puts end_line


  #Close both input and output file
  input_file.close
  output_file.close
end
