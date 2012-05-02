# DNSDB

DNSDB provides web services to manage DNS records and collections of IPs.

## DNSDB Resources

DNSDB manages four resources:

* Subnets
* IPs
* Domains
* Records

### Subnets

A subnet is a collection of IPs. To create a subnet you specify a network
and its bit mask like this:

    $ dnsdb create subnets 192.168.1.0/24

This will create the subnet as well as the related 256 entries in the IP table.
You cannot modify this subnet once it's created, but you can delete it.  All IPs
in a subnet have a state of <code>available</code> before it can can be deleted.
The below command deletes a particular subnet:

    $ dnsdb delete subnets 192.168.1.0/24

You can get a list of all subnets

    $ dnsdb get subnets

Or the details of a particular subnet

    $ dnsdb get subnets 192.168.1.0/24
 
You cannot create overlapping subnets.

### IPs

IPs are part of a subnet.  To list all of the IPs in a particular subnet specify
`--subnet` on the command line

    $ dnsdb get ips --subnet 192.168.1.0/24

You can't directly create or delete IPs.  You must create the corrisponding 
subnet and IPs will be created for you.

Each IP has an associated state.  Valid states are:

* <code>in_use</code>
* <code>available</code>

You can allocate an IP from the 192.168.1.0/24 subnet like this:

    $ dnsdb update ips --subnet 192.168.1.0/24 --state in_use

This will choose an available IP from this subnet and change its state to 
<code>in_use</code>.  If you want to allocate a particular IP just specify the
ip when updating the state:

    $ dnsdb update ips 192.168.1.44 --state in_use

### Domains

Domains (sometimes called zones) are a portion of a domain name space that is 
tracked by this system.  

You can create a domain like this:

    $ dnsdb create domains --name example.com --type NATIVE

When you fetch this domain you'll see there are several other fields which you
can modify (or set at create time):

    $ dnsdb get domain example.com
    {
      "id": 1,
      "name": "example.com",
      "type": "NATIVE",
      "notified_serial": null,
      "master": null,
      "last_check": null,
      "account": null
    }

The domain resource is designed to be read directly by the 
[PowerDNS](http://powerdns.com) server.  Read the PowerDNS docs for details on 
these fields.

When you create a domain that does not have a type of <code>SLAVE</code> a SOA
record for the domain is automatically created.  You can change the values of 
this SOA record by modifying the record resource (see the next section).

You cannot delete a domain unless you have first deleted all associated records.

### Records

Records are the basic unit of DNS.  You can create a record like this:

    $ dnsdb create records --type A --name foo.example.com --content 192.168.1.22

This will create a record that looks like this:

    $ dnsdb get records 17 
    {
      "id": 17,
      "domain_id": 1,
      "name": "foo.example.com",
      "content": "192.168.1.22",
      "type": "A",
      "ttl": null,
      "prio": null,
      "change_date": null
    }

You have to use the id field rather then the name to uniquely identify a record.
This is because DNS allows two records with the same name.

These records are designed to be read directly by 
[PowerDNS](http://powerdns.com).  See the PowerDNS docs for details about how 
each of these fields are used.

Note that the domain was automatically determined for you.  This is done using
a best fit algorithm.  You can override this by specifying 
<code>--domain</code> when creating or updating the record.

If your DNS server is configured to read this data (i.e. PowerDNS is pointing at
the DNSDB database) you should be able query this newly created record:

    $ host -t A foo.example.com
    foo.example.com has address 192.168.1.22

When you create an A record the associated PTR record is created for you.  If 
the necessary <code>in-addr.arpa</code> domain does not exist, it is 
automatically created as well.  Automatic creation of domains only happens when
the PTR records are automatically created.  Directly creating records in a 
domain that doesn't exist will result in an error.

When you delete an A record the associated PTR record is also deleted.  The 
<code>in-addr.arpa</code> domain is not deleted even if this is the last record 
in that zone.  When the name or content of an A record is modified the 
associated PTR record is deleted and a new PTR record matching the modified A 
record is created.

Anytime you modify any records in a given zone the SOA record's serial number is
automatically incremented for you.  The <code>yyyymmddnn</code> format for 
serial numbers as recommended in 
[RFC1537](http://www.faqs.org/rfcs/rfc1537.html) is respected.

When you create A records the content must be a valid (and existant) IP 
resource.  If the state is <code>available</code> it will automatically be set
to <code>in_use</code> for you.  You will not be able to set the IP to 
<code>available</code> until you first delete the associated A record.  Deleting
the A record will automatically set the IP to <code>available</code>.

## FAQ

#### What about IPv6, DNSSEC, etc?

#### Does DNSDB automatically manage PTR and SOA records for me?

#### How do I turn up a DNS server to serve the data that's in DNSDB?

#### Can I use another DNS server besides PowerDNS?

