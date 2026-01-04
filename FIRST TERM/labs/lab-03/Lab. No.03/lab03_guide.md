# Objective

Continue learning the installation of base software, particularly DNS
and NTP services, complemented with knowledge of Shell programming.

# Tools to Use

Computers

Internet access

Virtualization software

# Introduction

We continue working on a company's infrastructure, which typically
includes various IT infrastructure ser- vices. It comprises wired and
wireless user stations and servers (both physical and virtualized), all
connected through switches (Layer 2 and 3), wireless devices, and
routers that connect to the Internet. It's also com- mon to have cloud
infrastructures from which resources are provisioned according to the
organization's needs. Within the servers, services such as web, DNS,
email, database, storage, and applications, among others, can be found.
Let's recall the base configuration we are using:

![](media/image1.jpeg){width="5.088333333333333in"
height="2.915937226596675in"}

In this part of the lab, we will focus on continuing to prepare our
servers.

# Installation of Base Software

Perform the activities listed below on the application layer protocols:
DNS, as well as the specified Shell commands.

## Linux DNS Server - BIND

> **\[For groups of 1, 2, and 3 students\]**

As we have seen in class, a key service in an enterprise environment is
the Domain Name Resolution - DNS service. In this lab, we will configure
this service using test domains.

The domains to be configured, depending on the number of students in the
group, are:

1.  student 1.com.it

2.  student 2.org.uk

3.  student 3.gov.jp

**Note:** Replace "student n" with the group's name/surname (e.g.,
claudia.net.co). For each domain, the following must be defined:

3 server names with their corresponding IPv4 addresses (Use the ones
from the range assigned at the beginning of the semester). For now, only
name resolution will be visible; as we configure other services, we will
add them to the DNS, and we will be able to access those servers by
name.

2 servers with their corresponding IPv6 addresses.

2 aliases for 2 servers with IPv4 addresses and 1 server with an IPv6
address (Choose any names you prefer).

The implementation should be carried out using virtual machines: one
Solaris, one Windows Server, one Linux Slackware, and one CentOS (groups
of 3 students), two of them located on one physical computer and the
others on the other physical computer assigned to the groups. The
installation should be done as follows:

> For the domain **student 1.com.it**:

- Primary DNS server on a Solaris virtual machine.

- Secondary DNS servers on a Linux Slackware virtual machine and Windows
  Server.

> For the domain **student 2.org.uk**:

- Primary DNS server on a Slackware virtual machine.

- Secondary DNS servers on a Solaris virtual machine and Windows Server.
  In the case of a 3-student group, replace Windows Server with CentOS.

> For the domain **student 3.gov.jp**:

- Primary DNS server on a CentOS virtual machine.

- Secondary DNS servers on a Windows Server virtual machine and
  Slackware.

The secondary machine for student1.com.it and the primary for
student2.org.uk are the same, and so on (a total of 3 or 4 servers will
be configured for the DNS service, depending on the number of students
in the group). For testing functionality, change the DNS client
configuration on the other virtual machines you've set up and test name
resolution or use the nslookup command.

You must be able to use your DNS server to resolve names within your
domains and external domains. For example, it should correctly resolve
entries like:

server 1.student 1.com.it

server 2.student 1.com.it

server 3.student 2.org.uk

alias 1.student 2.org.uk

[www.escuelaing.edu.co](http://www.escuelaing.edu.co/)

[www.google.com](http://www.google.com/)

Below is an example of how to configure the primary DNS service on
Slackware. The highlighted yellow parts indicate what should be added to
the configuration files or replaced with the names of your domains or
specific IP addresses:

1.  If required, install the DNS package from the Linux CD/Image.

2.  Check that the packages were installed (for example, on Slackware,
    use pkgtools to verify).

3.  Configure the service.

// This section is used to create the reverse zone (according to the

// functionality of the DNS service). However, we will not configure it

// in this lab, so it can be omitted. zone \"0.0.127.in-addr.arpa\" IN {

> type master;
>
> file \"127.0.0.rev\"; allow-update { none; };
>
> };

slackware# mkdir /etc/DNS slackware# vi /etc/named.ca

> ;

; Root name servers

> ;

; 3600000 IN NS A.ROOT-SERVERS.NET

> ;

; Root name servers by address

// Search online for the list of root servers. Initially, include only

// one and perform tests, then add at least two more. A.ROOT-SERVER.NET
3600000 IN A abc.def.ghi.jkl

;A.ROOT-SERVER.NET 3600000 IN AAAA 2001:503:BA3E::2:30 B.ROOT-SERVER.NET
3600000 IN A mno.pqr.stu.vwx

slackware# vi /etc/DNS/my_domain.hosts

> ;

; /etc/DNS/my_domain.hosts file

> ;
>
> ;

; INCLUDE UPDATE SOA HEADER

\$INCLUDE named.soa ; you can include a file or directly

; place the information here. In this example, an

; additional file is included.

> ;

; Name Server(s)

> ;

my_domain. IN NS this_server.my_domain. ; give this server a name

> ; (e.g., dns.my_domain).

; Mail Server(s)

> ;

;my_domain. IN MX 10 mail_server.my_domain.

> ;

; Address for localhost

> ;

localhost.my_domain. IN A 127.0.0.1

> ;

; Addresses for canonical names

> ;

this_server.my_domain. IN A dir_ip_dns_server real_name_1.my_domain. IN
A dir_ip_server_1 real_name_2.my_domain. IN A dir_ip_server_2

> ;

; The configuration for IPv6 is not shown here. You should review how

; to configure it.

> ;

; Aliases

> ;

alias_1.my_domain. IN CNAME real_name_1.my_domain. alias_2.my_domain. IN
CNAME real_name_2.my_domain.

slackware# vi /etc/DNS/named.soa

> ;

; /etc/DNS/named.soa file

; Name server SOA file

> ;

@ IN SOA this_server.my_domain. root.my_domain. ( 2020050101 ; Serial

> ; The number is usually consecutive. The administrator
>
> ; may choose any number. For example, 001, 002, etc. In this
>
> ; example, the format used is yyyyMMddxx (yyyy: year,
>
> ; mm: month, dd: day, xx: consecutive number of the day the
>
> ; modifications are being made).
>
> )

slackware# /usr/sbin/named start

4.  What are the A and AAAA records in the root servers file?

5.  What are the NS, MX, A, and CNAME records in the particular domain
    file?

6.  Check the system logs to verify that the service is functioning
    correctly.

7.  Test its functionality on a client.

    i.  Configure a client computer to use the DNS server you just set
        up.

    ii. Use the nslookup command to check its operation. Make a video of
        no more than 5 minutes to explain it.

        A.  What is the nslookup command used for?

        B.  Test its operation.

        C.  Change the DNS server to the school's DNS server and repeat
            the same queries from the previous point. Document the
            results.

        D.  Use the command set type=NS. What did you get? Explain the
            results.

        E.  Use the command set debug. What did you get? Explain the
            results.

        F.  Use the command set type=A. What did you get? Explain the
            results.

        G.  Use the command set q=MX. What did you get? Explain the
            results.

8.  Test its functionality on the DNS server.

    i.  Perform the previous step directly on the DNS server. Does it
        work? Why?

    ii. Solve the problem and show the final IP configuration of the
        server.

9.  Configure the domain resolution service -- DNS (DNS Server) so that
    it is activated during system startup.

10. Show the configuration to your instructor.

## Other Useful Commands

> **\[For groups of 1, 2, and 3 students\]**

Write Shell programs for the Solaris and Linux Slackware servers that:

(a) Allow configuring a task to run periodically on the system. The user
    will specify the task to be executed and its frequency via the
    command line. The parameters should NOT be prompted inter- actively.
    For example:

(b) Build a Shell with a menu of options, where one option is to exit,
    and the others execute the desired command and return to the options
    menu. The menu should allow:

Displaying the processes currently running on a server. Show the process
name, its identifier, memory usage percentage, and CPU usage percentage.

Searching for a given process by the user and displaying its full
information.

Killing/closing a running process.

Restarting a running process.

(c) Create a Shell that allows traversing the file system from a given
    directory, including subdirectories, and shows the n smallest files
    within a size specified by the user. The output should indicate:
    file name, path where it is located, and size. The execution should
    look like:

For groups of 3 students, write PowerShell programs for Windows Server
that allow completing points b and c mentioned in this section. Groups
of one student should create the Shell scripts for Solaris.

**Note:** Show the operation of the servers and Shell scripts to your
instructor.
