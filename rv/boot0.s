#
# RVOOM! Risc-V superscalar O-O
# Copyright (C) 2020 Paul Campbell - paul@taniwha.com
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 

#
#	system boot	- we read GPIO bit 0 if not set we're running
#			  in a verilog simulator that's back loading dram
#
#			- otherwise we load from the dummy 'sd' driver (for
#			  initial AWS sims) - we load the 256-byte block at 0xffff_ff00
#			  and look for:
#			0: address
#			8: length (in 256 byte blocks)
#			16: address
#			24: length
#			....
#			a 0 length terminates the list
#
start:
	li	t4, 0xffffffffffffe000		# address of gpio controller
	ld	t1, 0(t4)			# boot options

	and	t1, t1, 1			# bit 0 means skip to boot 
	beqz	t1, start_code
	li	s0, 0				# offset into address list
	li	t4, 0xffffffffffffd000		# address of sd controller
	li	t1, 0x0				# memory load

section_loop:	
	li	t2, 0xffffffff  		# read 
	sd	t2, 48(t4)			# address
	li	a0, 1
	sd	a0, 40(t4)			# start read

2:		ld	a1, 16(t4)		# wait for done
		and	a1, a1, 0x2
	bnez	a1, 2b

	li	a1, -1
skip:		ld      t2, 0(t4)		# skip stuff we've already done
		ld	t3, 0(t4)
		add	a1, a1, 1
		bne	a1, s0, skip

	add	a1, a1, 1
	li	t0, 256/16
dump:		ld	a0, 0(t4)
		ld      a0, 0(t4)
		add	a1, a1, 1
		bne	a1, t0, dump

	beqz	t3, start_code_load
	add	s0, s0, 1
	
	li	a0, 1
1:	
		srli	s1, t2, 8
		sd	s1, 48(t4)			# address
		sd	a0, 40(t4)			# start read
		add	t3, t3, -1
2:
			ld	a1, 16(t4)			# wait for done
			and	a1, a1, 0x2
			bnez	a1, 2b

		li	a1, 256/8
3:			ld 	a2, 0(t4)			# copy read data
			sd	a2, (t2)
			add	t2, t2, 8
			add	a1, a1, -1
			bnez	a1, 3b
		bnez	t3, 1b
	j	section_loop

start_code_load:
	fence.i

start_code:
	csrr    a0, mhartid
	li	a1, 0xfffffffffffe0000	# dtb rom
	li	a2, 0x4942534f
	jalr	x0, x0
	nop
	nop
	.end
