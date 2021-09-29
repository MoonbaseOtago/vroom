
#define B(a, b) (((a)>>(b))&1)			// bit b
#define F(a, b, w) (((a)>>(b))&((1<<w)-1)) 	// field from bits b+w-1:b
#define G 3	// guard bits
uint32_t
fp32_add_sub(uint32_t a, uint32_t b, bool sub)
{
	int sign_a = bit(a, 31);
	int sign_b = bit(a, 31);

	int mantissa_a, mantissa_b;

	exp_a = F(a, 23, 8); 
	exp_b = F(b, 23, 8); 
	if (exp_a == 0) {
		mantissa_a = (F(a, 0, 23)<<G);
		exponent_a = -126;
	} else {
		mantissa_a = (1<<(23+G))|(F(a, 0, 23)<<G);
		exponent_a = exp_a-127;
	}
	if (exp_b == 0) {
		mantissa_b = F(b, 0, 23)<<G);
		exponent_b = -126;
	} else {
		mantissa_b = (1<<(23+G))|(F(b, 0, 23)<<G);
		exponent_b = exp_b-127;
	}

	// normalise
	if (exponent_a < exponent_b) {
		int sticky_a;
		if ((exponent_b-exponent_a) > 3) {
			sticky_a = (F(mantissa_a, 3, exponent_b-exponent_a-3) != 0 ?1:0);
		} else {
			sticky_a = 0;
		}
		mantissa_a = (mantissa_a>>(exponent_b-exponent_a)) | sticky_a;
		exponent = exponent_b;
	} else
	if (exponent_a > exponent_b) {
		int sticky_b;
		if ((exponent_a-exponent_b) > 3) {
			sticky_b = (F(mantissa_b, 3, exponent_a-exponent_b-3) != 0 ?1:0);
		} else {
			sticky_b = 0;
		}
		mantissa_b = (mantissa_b>>(exponent_a-exponent_b)) | sticky_b;
		exponent = exponent_a;
	} else {
		exponent = exponent_a;
	}
	if (sign_a) {
		if (sub?sign_b:!sign_b) {
			sign = 1;
			cin = 0;
		} else {
			mantissa_a = ~mantissa_a;
			sign = 0;
			cin = 1;
		}
	} else {
		sign = 0;
		if (sub?sign_b:!signb) {
			mantissa_b = ~mantissa_b;
			cin = 1;
		} else {
			cin = 0;
		}
	}
	mantissa = mantissa_a + mantissa_b + cin;
	if (B(mantissa, 31)) {	// sign?
		sign = 1;
		mantissa = -mantissa;
	}
	rnd = mantissa&0x7;		// isolate roundsing bits
	mantissa = mantissa>>3;		// 
	switch (rnd) {
	0:	// RNE - round to nearest, ties to even
		if (rnd > 4 || (rnd==4 && mantissa&1))
			mantissa++;
		break;
	1:	// RTZ - round to zero
		break;	
	2:	// RDN - round down
		if (sign && rnd)
			mantissa--;
		break;
	3:	// RUP - round up
		if (!sign && rnd)
			mantissa++;
		break;
	4:	// RMM - round to nearest ties to max magnitude
		if (rnd >= 4)
			mantissa++;
		break;
	}
	exponent += 127;
	return (sign<<31)|(exponent<<23)|(mantissa&0x0x7fffff);
}
