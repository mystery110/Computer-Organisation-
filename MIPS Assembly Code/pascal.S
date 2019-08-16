.data
.text

main:
	li $a0,10
	li $a1,5
	li $v0,0
	jal pascal1
	j exit2
	
pascal1:
	beq $a0,$a1,exit
	beq $a1,$zero,exit
	addi $sp,$sp,-12
	sw $a1,0($sp)
	sw $a0,4($sp)
	sw $ra,8($sp)
	addi $a0,$a0,-1
	addi $a1,$a1,-1
	jal pascal1
	addi $a1,$a1,1
	jal pascal1
	lw $ra,8($sp)
	lw $a0,4($sp)
	lw $a1,0($sp)
	addi $sp,$sp,12
	jr $ra
exit:
	addi $v0,$v0,1
	jr $ra

exit2:
