# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags {
    Name = "${var.clustername}-vpc"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.default.id}"
  tags {
    Name = "${var.clustername}-igw"
  }
}
resource "aws_eip" "eip" {
  count = "${length(var.public_subnets)}"
  vpc = true
  tags {
    Name = "${var.clustername}-eip-${count.index}"
  }
}
resource "aws_nat_gateway" "public" {
  count = "${length(var.public_subnets)}"
  allocation_id = "${element(aws_eip.eip.*.id, count.index)}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  depends_on = ["aws_internet_gateway.igw","aws_eip.eip"]
  tags {
    Name = "${var.clustername}-ngw-${count.index}"
  }
}
resource "aws_subnet" "public" {
  count = "${length(var.public_subnets)}"
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "${var.public_subnets[count.index]}"
  tags {
    Name = "${var.clustername}-public-${count.index}"
  }
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
}
resource "aws_subnet" "private" {
  count = "${length(var.private_subnets)}"
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "${var.private_subnets[count.index]}"
  tags {
    Name = "${var.clustername}-private-${count.index}"
  }
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
}
resource "aws_route_table" "public" {
  count = "${length(var.public_subnets)}"
  vpc_id = "${aws_vpc.default.id}"
  tags {
    Name = "${var.clustername}-public-${count.index}"
  }
  depends_on = ["aws_internet_gateway.igw"]
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
}
resource "aws_route_table" "private" {
  count = "${length(var.private_subnets)}"
  vpc_id = "${aws_vpc.default.id}"
  tags {
    Name = "${var.clustername}-private-${count.index}"
  }
  depends_on = ["aws_nat_gateway.public"]
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.public.*.id, count.index)}"
  }
}
resource "aws_route_table_association" "public" {
  count = "${length(var.public_subnets)}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"
}
resource "aws_route_table_association" "private" {
  count = "${length(var.private_subnets)}"
  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}
