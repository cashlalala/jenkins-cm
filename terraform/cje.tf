resource "aws_security_group" "cje" {
  name = "cje"
  description = "Internet traffic"
  vpc_id      = "${aws_vpc.cjp.id}"

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 35464
    to_port = 35464
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_instance" "cje" {
  count = "${var.cje.count}"
  ami = "${var.cje_ami_id}"
  instance_type = "${var.cje.instance_type}"
  tags {
    Name = "cje"
  }
  subnet_id = "${aws_subnet.cjp.id}"
  vpc_security_group_ids = [
    "${aws_security_group.ssh.id}",
    "${aws_security_group.cje.id}",
    "${aws_vpc.cjp.default_security_group_id}"
  ]
  depends_on = ["aws_route.internet_access", "aws_efs_mount_target.cjp"]
  provisioner "remote-exec" {
    connection {
      user = "${var.ssh_user}"
      password = "${var.ssh_pass}"
    }
    inline = [
      "sudo service jenkins stop",
      "sudo cp /data/jenkins/{license.xml,config.xml} /tmp/",
      "sudo cp -r /data/jenkins/jobs /tmp/",
      "sudo mount -t nfs4 -o nfsvers=4.1 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).${aws_efs_file_system.cjp.id}.efs.${var.region}.amazonaws.com:/ /data/",
      "sudo mkdir -p /data/jenkins/plugins",
      "sudo wget https://updates.jenkins-ci.org/latest/swarm.hpi -O /data/jenkins/plugins/swarm.hpi",
      "sudo mv /tmp/license.xml /tmp/config.xml /data/jenkins/",
      "sudo mv /tmp/jobs /data/jenkins/jobs",
      "sudo chown -R jenkins:jenkins /data/jenkins/",
      "sudo service jenkins start"
    ]
  }
}

output "cje_public_ip_0" {
  value = "${aws_instance.cje.0.public_ip}"
}

output "cje_private_ip_0" {
  value = "${aws_instance.cje.0.private_ip}"
}

output "cje_public_ip_1" {
  value = "${aws_instance.cje.1.public_ip}"
}

output "cje_private_ip_1" {
  value = "${aws_instance.cje.1.private_ip}"
}