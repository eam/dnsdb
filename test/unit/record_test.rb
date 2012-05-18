require 'test_helper'

class RecordTest < ActiveSupport::TestCase
  test "creating an A record creates PTR" do
    assert Record.create(
      :name    => "foo.example.com",
      :domain  => Domain.first,
      :type    => "A",
      :content => "10.22.33.44"
    ).valid?

    # created one A, PTR and a new SOA (for reverse)
    # another A/PTR pair and two SOA records were created by fixtures
    assert_equal 2, Record.where(:type => "PTR").count
    assert_equal 2, Record.where(:type => "A").count
    assert_equal 3, Record.where(:type => "SOA").count
    assert_equal 7, Record.count

    # two domains existed in fixtures, one was created for new PTR
    assert_equal 3, Domain.count

    ptr = Record.where(:type => "PTR").last
    assert_equal "44.33.22.10.in-addr.arpa", ptr.name
    assert_equal "33.22.10.in-addr.arpa", ptr.domain.name
    assert_equal "foo.example.com", ptr.content
  end

  test "create on a record updates SOA serial numbers" do
    r = Record.where(:type => "A").first
    a_soa = r.domain.soa
    ptr_soa = r.ptr.domain.soa
    a_serial_was = a_soa.content.split(/\s+/)[2]
    ptr_serial_was = ptr_soa.content.split(/\s+/)[2]

    # updating a record should bump the soa serial numbers
    # for both the A and PTR SOA records
    r.name = "abc.example.com"
    r.save!

    a_soa.reload
    ptr_soa.reload
    assert a_serial_was < a_soa.content.split(/\s+/)[2]
    assert ptr_serial_was < ptr_soa.content.split(/\s+/)[2]
  end

  test "updating an A record updates PTR" do
    r = Record.where(:type => "A").first
    r.name = "bar.example.com"
    r.save!

    assert_equal 1, Record.where(:type => "PTR").count
    assert_equal 1, Record.where(:type => "A").count
    assert_equal 2, Record.where(:type => "SOA").count
    assert_equal 4, Record.count
    assert_equal 2, Domain.count

    ptr = Record.where(:type => "PTR").last
    assert_equal "bar.example.com", ptr.content

    # test changing the content to stay in the same reverse domain
    r.content = "11.22.33.60"
    r.save!

    ptr = Record.where(:type => "PTR").last
    assert_equal "60.33.22.11.in-addr.arpa", ptr.name
    assert_equal "33.22.11.in-addr.arpa", ptr.domain.name
    assert_equal 4, Record.count, "no extra records were created"

    # test changing the content to a different reverse domain
    r.content = "192.168.222.111"
    r.save!

    ptr = Record.where(:type => "PTR").last
    assert_equal "111.222.168.192.in-addr.arpa", ptr.name

    # there should be four records now:
    # three SOAs (one for new domain, one for old and one for reverse),
    # plus the A and the PTR
    assert_equal 5, Record.count

    # the 33.22.11 reverse domain is left alone and the 222.168.192 is created
    assert_equal 3, Domain.count
  end

  test "automatically set domain" do
    # create a couple of domains for this test
    Domain.create(
      :name => "foo.bar.baz.example.com",
      :type => "NATIVE"
    )
    baz_domain = Domain.create(
      :name => "baz.example.com",
      :type => "NATIVE"
    )

    r = Record.create(
      :type    => 'A',
      :name    => 'bogus.example.com',
      :content => '192.168.1.1'
    )
    assert_equal "example.com", r.domain.name

    r = Record.create(
      :type    => 'A',
      :name    => 'bar.baz.example.com',
      :content => '192.168.1.2'
    )
    assert_equal "baz.example.com", r.domain.name

    # override what is automatically determined
    r = Record.create(
      :type      => 'A',
      :name      => 'blonk.foo.bar.baz.example.com',
      :content   => '192.168.1.3',
      :domain_id => baz_domain.id
    )
    assert_equal "baz.example.com", r.domain.name

    r = Record.create(
      :type    => 'A',
      :name    => 'blink.foo.bar.baz.example.com',
      :content => '192.168.1.4',
      :domain  => baz_domain
    )
    assert_equal "baz.example.com", r.domain.name

    # throws because bogus.com doesn't exist in domains table
    assert_raise RuntimeError do
      Record.create(
        :type    => 'A',
        :name    => 'foo.bogus.com',
        :content => '192.168.1.3'
      )
    end

    # create other types
    #TODO this test fails.  it should work
    if false
      assert_valid Record.create(
        :type => "NS",
        :name => "example.com",
        :content => "ns1.example.com"
      )
    end
  end

  test "two A records creates one PTR" do
      r1 = Record.create(
        :type    => 'A',
        :name    => 'abc.example.com',
        :content => '192.168.1.10'
      )

      r2 = Record.create(
        :type    => 'A',
        :name    => 'def.example.com',
        :content => '192.168.1.10'
      )

      assert_equal 1, Record.where(:name => "10.1.168.192.in-addr.arpa").count, "only one PTR was created"
      ptr = Record.where(:name => "10.1.168.192.in-addr.arpa").first
      assert_equal "abc.example.com", ptr.content, "the PTR record points to the first record"

      assert_equal 0, Record.where(:content => "def.example.com").count, "no ptr was found for 2nd record"

      r2.destroy
      assert_equal 1, Record.where(:name => "10.1.168.192.in-addr.arpa").count
      ptr = Record.where(:name => "10.1.168.192.in-addr.arpa").first
      assert_equal "abc.example.com", ptr.content, "the PTR record still points to the first record after deleting the second"
  end

  test "can use an in_use IP" do
    ip = Ip.first
    ip.state = "in_use"
    ip.save

    assert_not_nil Record.create(
        :type    => 'A',
        :name    => 'foo.example.com',
        :content => ip.ip
    )
  end

  test "cannot use an unmanaged IP" do
    r = Record.create(
      :type    => 'A',
      :name    => 'foo.example.com',
      :content => '8.8.8.8'
    )

    assert_equal "8.8.8.8 is not a managed IP resource", r.errors.messages[:content][0]
  end

  test "IP is state is managed" do
    ip = Ip.first
    assert_equal "available", ip.state
    r = Record.create(
      :type    => 'A',
      :name    => 'foo.example.com',
      :content => ip.ip
    )
    ip.reload
    assert_equal "in_use", ip.state

    # properly managed when updated
    another_ip = Ip.last
    r.content = another_ip.ip
    r.save

    ip.reload
    assert_equal "available", ip.state

    another_ip.reload
    assert_equal "in_use", another_ip.state

    # IP is returned to available when A record is deleted
    r.destroy

    another_ip.reload
    assert_equal "available", another_ip.state
  end

  # it is valid for two A records to have the same name
  # this is used with roundrobin load distribution
  test "A records with same name" do
    ip = Ip.first
    assert Record.create(
      :type    => 'A',
      :name    => 'foo.example.com',
      :content => ip.ip
    ).valid?

    another_ip = Ip.last
    assert Record.create(
      :type    => 'A',
      :name    => 'foo.example.com',
      :content => another_ip.ip
    ).valid?

    # there should be two PTR records both pointing at foo.example.com
    assert_equal 2, Record.where(:type => 'PTR', :content => "foo.example.com").count
  end

  test "records with same name type and content" do
    ip = Ip.first
    assert Record.create(
      :type    => 'A',
      :name    => 'foo.example.com',
      :content => ip.ip
    ).valid?

    r = Record.create(
      :type    => 'A',
      :name    => 'foo.example.com',
      :content => ip.ip
    )

    assert !r.valid?
    assert_equal "a record with the same name and content already exists",
      r.errors.messages[:base][0]

    # but records with different types and the same content/name should be ok
    assert Record.create(
      :type    => 'TXT',
      :name    => 'foo.example.com',
      :content => ip.ip
    ).valid?
  end

  test "name must match domain name" do
    d = Domain.first
    r = Record.create(
      :domain_id => d.id,
      :type      => 'A',
      :name      => 'foo.bar.com',
      :content   => Ip.first.ip
    )

    assert !r.valid?
    assert_equal "name does not seem to be in domain", r.errors.messages[:domain][0]
  end
end
