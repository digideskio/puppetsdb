## Puppet SDB

This is an Amazon SimpleDB
[ENC](http://docs.puppetlabs.com/guides/external_nodes.html) backend for
[Puppet](http://puppetlabs.com/). It allows a Puppet master to retrieve a
node's configuration from SimpleDB. The utility also provides the capability to
create, update, and delete node configurations in SimpleDB.

## Installation

* gem install puppetsdb
* create `$HOME/.puppetsdb/config.yml` 
* create `/etc/puppetsdb/config.yml` for system-wide settings
* create `~puppet/.puppetsdb/config.yml` for the Puppet Master process

## Configuration

### Puppet SDB Utility

The configuration in `$HOME/.puppetsdb/config.yml` merges with and overrides
the parameters in `/etc/puppetsdb/config.yml`. This means that the AWS
credentials can be kept in the former while the latter contains generic
settings. This is useful when multiple users utilize their own credentials when
reading or modifying the SimpleDB ENC.

    # /etc/puppetsdb/config.yml
    aws:
      simple_db_endpoint: sdb.amazonaws.com
      max_retries: 2
    puppetsdb:
      domain: puppetenc

    # $HOME/.puppetsdb/config.yml
    aws:
      access_key_id: REPLACE_WITH_ACCESS_KEY_ID
      secret_access_key: REPLACE_WITH_SECRET_ACCESS_KEY

If the environment variable 'HOME' is not set, the configuration file
`~puppet/.puppetsdb/config.yml` will be read.

The `aws:` section parameters are the configuration options supported by the
[AWS-SDK](http://aws.amazon.com/sdkforruby/). This section configures AWS only.

The `puppetsdb:` section parameters configure puppetsdb. The only supported
option at this time is the name of the SimpleDB domain.

### Puppet Master ENC

Configure the Puppet Master to use the SimpleDB ENC by using the following parameters:

    # /etc/puppet/puppet.conf
    node_terminus = exec
    external_nodes = /usr/bin/puppetsdb get

Restart the Puppet Master process.

Ensure that the puppet user has the correct AWS credentials

    # ~puppet/.puppetsdb/config.yml
    aws:
      access_key_id: REPLACE_WITH_ACCESS_KEY_ID
      secret_access_key: REPLACE_WITH_SECRET_ACCESS_KEY

## Usage

See an overview of the commands:

    # /usr/bin/puppetsdb help

Before you can creat any node configurations you must first create the SimpleDB domain specified in the configuration:

    # /usr/bin/puppetsdb createdomain puppetenc

This command can be used for general-purpose creation of a SimpleDB domain that is unrelated to the Puppet ENC.

Verify the creation of the domain with (this will list all SimpleDB domains for the AWS account):

    # /usr/bin/puppetsdb listdomains

Create a sample YAML file representing a node's configuration:

    # sample_node.yml
    classes:
      common:
      puppet:
      ntp:
        ntpserver: 0.pool.ntp.org
    environment: development

Set a node configuration with:

    # /usr/bin/puppetsdb set node_name [sample_node.yml]

If no YAML file is specified on the command line, STDIN is used to read the YAML data.

List all the known nodes:

    # /usr/bin/puppetsdb list

Retrieve a node's configuration with:

    # /usr/bin/puppetsdb get node_name

The STDIN method of updating a node can be used to copy a node's configuration to another node.

    # /usr/bin/puppetsdb get source_node | /usr/bin/puppetsdb set dest_node

## To Do

* Tests
* Dynamic Registration using SNS and SQS as suggested in the [AWS Architecture Class Manual](http://awsu-arch.s3.amazonaws.com/student-manual/index.html)

## Bugs

* This gem was not thoroughly tested. More testing is in progress.

[Found a bug?](http://github.com/bwong114/puppetsdb/issues)

## Contact

* Mail

  bwong114 [at] gmail.com
