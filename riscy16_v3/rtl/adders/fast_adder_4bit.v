module fast_adder_4bit(a,b,cin,cout,out,Ggroup,Pgroup);
	input[3:0] a,b;
	input cin;
	output[3:0] out;
	output cout;
	output Ggroup,Pgroup;

	wire g0,g1,g2,g3;
	wire p0,p1,p2,p3;
	wire c1,c2,c3;

	assign g0=a[0]&b[0];
	assign g1=a[1]&b[1];
	assign g2=a[2]&b[2];
	assign g3=a[3]&b[3];
	assign p0=a[0]|b[0];
	assign p1=a[1]|b[1];
	assign p2=a[2]|b[2];
	assign p3=a[3]|b[3];

	assign c1=g0|(p0&cin);
	assign c2=g1|(g0&p1)|(p1&p0&cin);
	assign c3=g2|(g1&p2)|(p2&p1&g0)|(p2&p1&p0&cin);

	assign out[0]=a[0]^b[0]^cin;
	assign out[1]=a[1]^b[1]^c1;
	assign out[2]=a[2]^b[2]^c2;
	assign out[3]=a[3]^b[3]^c3;

	//cout=g3|(p3&g2)|(p3&p2&g1)|(p3&p2&p1&g0)|(p3&p2&p1&p0&cin);
	assign Pgroup = p3 & p2 & p1 & p0;
   assign Ggroup = g3 |
                    (p3 & g2) |
                    (p3 & p2 & g1) |
                    (p3 & p2 & p1 & g0);

    assign cout = Ggroup | (Pgroup & cin);

endmodule
